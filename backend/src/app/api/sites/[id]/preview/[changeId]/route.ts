import { NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { getUserFromRequest } from '@/lib/auth';
import { corsResponse, corsErrorResponse, handleCorsOptions } from '@/lib/cors';

const VERCEL_TOKEN = process.env.VERCEL_TOKEN || '';
const VERCEL_TEAM_ID = process.env.VERCEL_TEAM_ID || '';

export async function OPTIONS() {
  return handleCorsOptions();
}

async function checkVercelDeployment(projectName: string, branchName: string): Promise<{
  status: 'pending' | 'ready' | 'error';
  url?: string;
}> {
  try {
    const response = await fetch(
      `https://api.vercel.com/v6/deployments?projectId=${projectName}&teamId=${VERCEL_TEAM_ID}&target=preview&limit=5`,
      {
        headers: {
          Authorization: `Bearer ${VERCEL_TOKEN}`,
        },
      }
    );

    if (!response.ok) {
      return { status: 'pending' };
    }

    const data = await response.json();
    const deployment = data.deployments?.find(
      (d: { meta?: { githubCommitRef?: string }; state?: string }) =>
        d.meta?.githubCommitRef === branchName
    );

    if (!deployment) {
      return { status: 'pending' };
    }

    if (deployment.state === 'READY') {
      return { status: 'ready', url: `https://${deployment.url}` };
    }

    if (deployment.state === 'ERROR') {
      return { status: 'error' };
    }

    return { status: 'pending' };
  } catch (error) {
    console.error('Error checking Vercel deployment:', error);
    return { status: 'pending' };
  }
}

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string; changeId: string }> }
) {
  try {
    const tokenPayload = getUserFromRequest(request);

    if (!tokenPayload) {
      return corsErrorResponse('Unauthorized', 401);
    }

    const { id, changeId } = await params;

    const site = await prisma.site.findFirst({
      where: {
        id,
        userId: tokenPayload.userId,
      },
    });

    if (!site) {
      return corsErrorResponse('Site not found', 404);
    }

    const pendingChange = await prisma.pendingChange.findFirst({
      where: {
        id: changeId,
        siteId: site.id,
      },
    });

    if (!pendingChange) {
      return corsErrorResponse('Pending change not found', 404);
    }

    const projectName = site.vercelProjectId || site.repoName;
    const deploymentStatus = await checkVercelDeployment(projectName, pendingChange.branchName);

    if (deploymentStatus.status === 'ready' && deploymentStatus.url) {
      await prisma.pendingChange.update({
        where: { id: changeId },
        data: { previewUrl: deploymentStatus.url },
      });
    }

    return corsResponse({
      id: pendingChange.id,
      branchName: pendingChange.branchName,
      previewUrl: deploymentStatus.url || pendingChange.previewUrl,
      status: deploymentStatus.status,
      userMessage: pendingChange.userMessage,
      aiSummary: pendingChange.aiSummary,
      filesChanged: pendingChange.filesChanged,
      createdAt: pendingChange.createdAt,
    });
  } catch (error) {
    console.error('Get preview status error:', error);
    return corsErrorResponse('Internal server error', 500);
  }
}
