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

    const user = await prisma.user.findUnique({
      where: { id: tokenPayload.userId },
      select: {
        id: true,
        email: true,
        name: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    if (!user) {
      return corsErrorResponse('User not found', 404);
    }

    return corsResponse({ user });
  } catch (error) {
    console.error('Get user error:', error);
    return corsErrorResponse('Internal server error', 500);
  }
}
