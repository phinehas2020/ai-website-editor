import { GoogleGenerativeAI } from '@google/generative-ai';
import Anthropic from '@anthropic-ai/sdk';

const googleAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY || '');
const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY || '',
});

export type AIModel = 'gemini-flash' | 'gemini-pro' | 'claude-opus';

interface AIResponse {
  summary: string;
  files: Record<string, string>;
}

interface RepoFile {
  path: string;
  content: string;
}

function buildPrompt(files: RepoFile[], userMessage: string): string {
  let filesContent = '';
  for (const file of files) {
    filesContent += `FILE: ${file.path}\n\`\`\`\n${file.content}\n\`\`\`\n\n`;
  }

  return `You are an AI that modifies website code based on user requests.

Current files in the repository:
---
${filesContent}
---

User request: "${userMessage}"

RULES:
1. For text/color/content changes, prefer editing content/site.json if it exists
2. NEVER edit: next.config.js, package.json, any files in /api, .env files
3. Return ONLY valid JSON in this format:
{
  "summary": "Brief description of changes made",
  "files": {
    "path/to/file.tsx": "full new content...",
    "path/to/other.json": "full new content..."
  }
}
4. Only include files that need changes
5. Preserve all existing functionality
6. Do not include any text before or after the JSON object`;
}

function parseAIResponse(response: string): AIResponse {
  try {
    const jsonMatch = response.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      throw new Error('No JSON found in response');
    }

    const parsed = JSON.parse(jsonMatch[0]);

    if (typeof parsed.summary !== 'string' || typeof parsed.files !== 'object') {
      throw new Error('Invalid response structure');
    }

    return parsed as AIResponse;
  } catch (error) {
    console.error('Error parsing AI response:', error);
    console.error('Raw response:', response);
    throw new Error('Failed to parse AI response');
  }
}

async function callGemini(model: string, prompt: string): Promise<string> {
  const geminiModel = googleAI.getGenerativeModel({ model });
  const result = await geminiModel.generateContent(prompt);
  const response = await result.response;
  return response.text();
}

async function callClaude(prompt: string): Promise<string> {
  const message = await anthropic.messages.create({
    model: 'claude-opus-4-5-20251101',
    max_tokens: 8192,
    messages: [
      {
        role: 'user',
        content: prompt,
      },
    ],
  });

  const textBlock = message.content.find(block => block.type === 'text');
  if (!textBlock || textBlock.type !== 'text') {
    throw new Error('No text response from Claude');
  }
  return textBlock.text;
}

export async function generateCodeChanges(
  files: RepoFile[],
  userMessage: string,
  model: AIModel
): Promise<AIResponse> {
  const prompt = buildPrompt(files, userMessage);
  let rawResponse: string;

  switch (model) {
    case 'gemini-flash':
      rawResponse = await callGemini('gemini-2.0-flash', prompt);
      break;
    case 'gemini-pro':
      rawResponse = await callGemini('gemini-2.0-pro', prompt);
      break;
    case 'claude-opus':
      rawResponse = await callClaude(prompt);
      break;
    default:
      throw new Error(`Unknown model: ${model}`);
  }

  return parseAIResponse(rawResponse);
}

export function getAvailableModels(): { id: AIModel; name: string; description: string }[] {
  return [
    {
      id: 'gemini-flash',
      name: 'Gemini Flash',
      description: 'Fast and efficient for simple changes',
    },
    {
      id: 'gemini-pro',
      name: 'Gemini Pro',
      description: 'More capable for complex changes',
    },
    {
      id: 'claude-opus',
      name: 'Claude Opus',
      description: 'Most capable for sophisticated changes',
    },
  ];
}
