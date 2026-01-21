import { NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { getUserFromRequest } from '@/lib/auth';
import { corsResponse, corsErrorResponse, handleCorsOptions } from '@/lib/cors';

export async function OPTIONS() {
  return handleCorsOptions();
}

export async function GET(request: NextRequest) {
  try {
    const tokenPayload = getUserFromRequest(request);

    if (!tokenPayload) {
      return corsErrorResponse('Unauthorized', 401);
    }

    const sites = await prisma.site.findMany({
      where: { userId: tokenPayload.userId },
      orderBy: { createdAt: 'desc' },
      include: {
        pendingChanges: {
          where: { status: 'pending' },
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
    });

    return corsResponse({ sites });
  } catch (error) {
    console.error('Get sites error:', error);
    return corsErrorResponse('Internal server error', 500);
  }
}

export async function POST(request: NextRequest) {
  try {
    const tokenPayload = getUserFromRequest(request);

    if (!tokenPayload) {
      return corsErrorResponse('Unauthorized', 401);
    }

    const body = await request.json();
    const { name, repoName, vercelProjectId } = body;

    if (!name || !repoName) {
      return corsErrorResponse('Name and repoName are required', 400);
    }

    const site = await prisma.site.create({
      data: {
        name,
        repoName,
        vercelProjectId: vercelProjectId || null,
        userId: tokenPayload.userId,
      },
    });

    return corsResponse({ site }, 201);
  } catch (error) {
    console.error('Create site error:', error);
    return corsErrorResponse('Internal server error', 500);
  }
}
