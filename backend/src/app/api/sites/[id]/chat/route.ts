import { NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { getUserFromRequest } from '@/lib/auth';
import { corsResponse, corsErrorResponse, handleCorsOptions } from '@/lib/cors';
import { getRepoFiles, createBranch, commitFiles, getDefaultBranch } from '@/lib/github';
import { generateCodeChanges, AIModel } from '@/lib/ai';

const VERCEL_TEAM_ID = process.env.VERCEL_TEAM_ID || '';

export async function OPTIONS() {
  return handleCorsOptions();
}

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const tokenPayload = getUserFromRequest(request);

    if (!tokenPayload) {
      return corsErrorResponse('Unauthorized', 401);
    }

    const { id } = await params;
    const body = await request.json();
    const { message, model = 'gemini-flash' } = body;

    if (!message) {
      return corsErrorResponse('Message is required', 400);
    }

    const validModels: AIModel[] = ['gemini-flash', 'gemini-pro', 'claude-opus'];
    if (!validModels.includes(model)) {
      return corsErrorResponse('Invalid model selection', 400);
    }

    const site = await prisma.site.findFirst({
      where: {
        id,
        userId: tokenPayload.userId,
      },
    });

    if (!site) {
      return corsErrorResponse('Site not found', 404);
    }

    const defaultBranch = await getDefaultBranch(site.repoName);
    const files = await getRepoFiles(site.repoName, defaultBranch);

    if (files.length === 0) {
      return corsErrorResponse('No editable files found in repository', 400);
    }

    const aiResponse = await generateCodeChanges(files, message, model as AIModel);

    const changedFilePaths = Object.keys(aiResponse.files);
    if (changedFilePaths.length === 0) {
      return corsResponse({
        message: 'No changes needed for this request',
        summary: aiResponse.summary,
        filesChanged: [],
      });
    }

    const timestamp = Date.now();
    const branchName = `preview-${timestamp}`;

    const branchCreated = await createBranch(site.repoName, branchName, defaultBranch);
    if (!branchCreated) {
      return corsErrorResponse('Failed to create preview branch', 500);
    }

    const filesToCommit = changedFilePaths.map(path => ({
      path,
      content: aiResponse.files[path],
    }));

    const commitSuccess = await commitFiles(
      site.repoName,
      branchName,
      filesToCommit,
      `AI changes: ${aiResponse.summary}`
    );

    if (!commitSuccess) {
      return corsErrorResponse('Failed to commit changes', 500);
    }

    // Extract repo name if it contains owner (e.g. "owner/repo" -> "repo")
    const repoNameOnly = site.repoName.split('/').pop() || site.repoName;
    const projectName = site.vercelProjectId || repoNameOnly;
    const previewUrl = `https://${projectName}-git-${branchName}-${VERCEL_TEAM_ID}.vercel.app`;

    const pendingChange = await prisma.pendingChange.create({
      data: {
        siteId: site.id,
        branchName,
        previewUrl,
        userMessage: message,
        aiSummary: aiResponse.summary,
        filesChanged: changedFilePaths,
        status: 'pending',
      },
    });

    return corsResponse({
      pendingChangeId: pendingChange.id,
      branchName,
      previewUrl,
      summary: aiResponse.summary,
      filesChanged: changedFilePaths,
    });
  } catch (error) {
    console.error('Chat error:', error);
    return corsErrorResponse(
      error instanceof Error ? error.message : 'Internal server error',
      500
    );
  }
}
