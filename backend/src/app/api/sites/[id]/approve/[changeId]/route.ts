import { NextRequest } from 'next/server';
import { Prisma } from '@prisma/client';
import prisma from '@/lib/prisma';
import { getUserFromRequest } from '@/lib/auth';
import { corsResponse, corsErrorResponse, handleCorsOptions } from '@/lib/cors';
import { mergeBranch, deleteBranch, getDefaultBranch } from '@/lib/github';

export async function OPTIONS() {
  return handleCorsOptions();
}

export async function POST(
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
        status: 'pending',
      },
    });

    if (!pendingChange) {
      return corsErrorResponse('Pending change not found or already processed', 404);
    }

    const defaultBranch = await getDefaultBranch(site.repoName);
    const mergeSuccess = await mergeBranch(site.repoName, pendingChange.branchName, defaultBranch);

    if (!mergeSuccess) {
      return corsErrorResponse('Failed to merge changes', 500);
    }

    await deleteBranch(site.repoName, pendingChange.branchName);

    await prisma.changeHistory.create({
      data: {
        siteId: site.id,
        userMessage: pendingChange.userMessage,
        aiSummary: pendingChange.aiSummary,
        filesChanged: pendingChange.filesChanged as Prisma.InputJsonValue,
      },
    });

    await prisma.pendingChange.update({
      where: { id: changeId },
      data: { status: 'approved' },
    });

    return corsResponse({
      message: 'Changes approved and merged successfully',
      changeId: pendingChange.id,
    });
  } catch (error) {
    console.error('Approve change error:', error);
    return corsErrorResponse('Internal server error', 500);
  }
}
