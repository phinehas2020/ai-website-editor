# AI Website Editor Platform

An AI-powered platform for editing websites through natural language. The platform consists of a Next.js backend API and a SwiftUI iOS application.

## Project Structure

```
├── backend/           # Next.js 14 API (deployed to Vercel)
└── ios-app/          # SwiftUI iOS application
```

## Features

- **AI-Powered Editing**: Use natural language to describe website changes
- **Multiple AI Models**: Support for Gemini Flash, Gemini Pro, and Claude Opus
- **Live Previews**: Preview changes on Vercel before merging
- **GitHub Integration**: Automatic branch creation and merging
- **Change History**: Track all approved changes

## Backend Setup

### Prerequisites
- Node.js 18+
- PostgreSQL database (Neon recommended)

### Installation

```bash
cd backend
npm install
```

### Environment Variables

Create a `.env` file in the backend directory:

```env
# Database (Neon PostgreSQL)
DATABASE_URL="postgresql://user:password@host:5432/database?sslmode=require"

# Authentication
JWT_SECRET="your-jwt-secret-key-here"

# GitHub
GITHUB_TOKEN="ghp_your_github_token"
GITHUB_ORG="your-github-org-or-username"

# AI Providers
GOOGLE_AI_API_KEY="your-google-ai-api-key"
ANTHROPIC_API_KEY="your-anthropic-api-key"

# Vercel
VERCEL_TOKEN="your-vercel-token"
VERCEL_TEAM_ID="your-vercel-team-id"
```

### Database Setup

```bash
npx prisma migrate dev --name init
```

### Running the Backend

```bash
npm run dev
```

The API will be available at `http://localhost:3000`.

## iOS App Setup

### Prerequisites
- Xcode 15+
- iOS 17.0+

### Installation

1. Open `ios-app/AIWebsiteEditor.xcodeproj` in Xcode
2. Update the `baseURL` in `APIClient.swift` for production deployment
3. Build and run on simulator or device

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user

### Sites
- `GET /api/sites` - List user's sites
- `POST /api/sites` - Create new site
- `GET /api/sites/[id]` - Get site details
- `PUT /api/sites/[id]` - Update site
- `DELETE /api/sites/[id]` - Delete site

### Chat & Changes
- `POST /api/sites/[id]/chat` - Send AI chat message
- `GET /api/sites/[id]/preview/[changeId]` - Check preview status
- `POST /api/sites/[id]/approve/[changeId]` - Approve changes
- `POST /api/sites/[id]/reject/[changeId]` - Reject changes
- `GET /api/sites/[id]/history` - Get change history

## API Keys Setup

### GitHub Token
1. Go to https://github.com/settings/tokens
2. Generate new token (classic)
3. Select scopes: `repo` (full control)

### Vercel Token
1. Go to https://vercel.com/account/tokens
2. Create new token
3. Get Team ID from Vercel dashboard settings

### Google AI (Gemini)
1. Go to https://aistudio.google.com/app/apikey
2. Create API key

### Anthropic (Claude)
1. Go to https://console.anthropic.com/settings/keys
2. Create new key

## License

MIT
