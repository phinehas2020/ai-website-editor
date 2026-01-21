import { NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { getUserFromRequest } from '@/lib/auth';
import { corsResponse, corsErrorResponse, handleCorsOptions } from '@/lib/cors';

export async function OPTIONS() {
  return handleCorsOptions();
}

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const tokenPayload = getUserFromRequest(request);

    if (!tokenPayload) {
      return corsErrorResponse('Unauthorized', 401);
    }

    const { id } = await params;

    const site = await prisma.site.findFirst({
      where: {
        id,
        userId: tokenPayload.userId,
      },
      include: {
        pendingChanges: {
          orderBy: { createdAt: 'desc' },
        },
        changeHistory: {
          orderBy: { committedAt: 'desc' },
          take: 10,
        },
      },
    });

    if (!site) {
      return corsErrorResponse('Site not found', 404);
    }

    return corsResponse({ site });
  } catch (error) {
    console.error('Get site error:', error);
    return corsErrorResponse('Internal server error', 500);
  }
}

export async function PUT(
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
    const { name, vercelProjectId } = body;

    const existingSite = await prisma.site.findFirst({
      where: {
        id,
        userId: tokenPayload.userId,
      },
    });

    if (!existingSite) {
      return corsErrorResponse('Site not found', 404);
    }

    const site = await prisma.site.update({
      where: { id },
      data: {
        ...(name && { name }),
        ...(vercelProjectId !== undefined && { vercelProjectId }),
      },
    });

    return corsResponse({ site });
  } catch (error) {
    console.error('Update site error:', error);
    return corsErrorResponse('Internal server error', 500);
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const tokenPayload = getUserFromRequest(request);

    if (!tokenPayload) {
      return corsErrorResponse('Unauthorized', 401);
    }

    const { id } = await params;

    const existingSite = await prisma.site.findFirst({
      where: {
        id,
        userId: tokenPayload.userId,
      },
    });

    if (!existingSite) {
      return corsErrorResponse('Site not found', 404);
    }

    await prisma.pendingChange.deleteMany({
      where: { siteId: id },
    });

    await prisma.changeHistory.deleteMany({
      where: { siteId: id },
    });

    await prisma.site.delete({
      where: { id },
    });

    return corsResponse({ message: 'Site deleted successfully' });
  } catch (error) {
    console.error('Delete site error:', error);
    return corsErrorResponse('Internal server error', 500);
  }
}
