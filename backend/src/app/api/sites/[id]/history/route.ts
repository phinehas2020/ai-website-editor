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
    });

    if (!site) {
      return corsErrorResponse('Site not found', 404);
    }

    const history = await prisma.changeHistory.findMany({
      where: { siteId: site.id },
      orderBy: { committedAt: 'desc' },
    });

    return corsResponse({ history });
  } catch (error) {
    console.error('Get history error:', error);
    return corsErrorResponse('Internal server error', 500);
  }
}
