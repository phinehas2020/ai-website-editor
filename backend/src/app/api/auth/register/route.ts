import { NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { hashPassword, signToken, validateEmail, validatePassword } from '@/lib/auth';
import { corsResponse, corsErrorResponse, handleCorsOptions } from '@/lib/cors';

export async function OPTIONS() {
  return handleCorsOptions();
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { email, password, name } = body;

    if (!email || !password) {
      return corsErrorResponse('Email and password are required', 400);
    }

    if (!validateEmail(email)) {
      return corsErrorResponse('Invalid email format', 400);
    }

    const passwordValidation = validatePassword(password);
    if (!passwordValidation.valid) {
      return corsErrorResponse(passwordValidation.message || 'Invalid password', 400);
    }

    const existingUser = await prisma.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      return corsErrorResponse('User with this email already exists', 409);
    }

    const hashedPassword = await hashPassword(password);

    const user = await prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        name: name || null,
      },
    });

    const token = signToken({ userId: user.id, email: user.email });

    return corsResponse({
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        createdAt: user.createdAt,
      },
    }, 201);
  } catch (error) {
    console.error('Registration error:', error);
    return corsErrorResponse('Internal server error', 500);
  }
}
