export default function Home() {
  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: 'system-ui, -apple-system, sans-serif',
      backgroundColor: '#0a0a0a',
      color: '#ededed',
      padding: '2rem',
    }}>
      <main style={{ maxWidth: '600px', textAlign: 'center' }}>
        <h1 style={{ fontSize: '2.5rem', marginBottom: '0.5rem' }}>
          🌐 AI Website Editor API
        </h1>
        <p style={{ color: '#888', marginBottom: '2rem' }}>
          Backend service for the AI Website Editor platform
        </p>

        <div style={{
          backgroundColor: '#1a1a1a',
          borderRadius: '12px',
          padding: '1.5rem',
          textAlign: 'left',
          marginBottom: '2rem',
        }}>
          <h2 style={{ fontSize: '1.2rem', marginBottom: '1rem', color: '#10b981' }}>
            ✓ API Status: Online
          </h2>

          <h3 style={{ fontSize: '1rem', marginBottom: '0.5rem', color: '#888' }}>
            Available Endpoints:
          </h3>
          <ul style={{ listStyle: 'none', padding: 0, margin: 0, fontSize: '0.9rem' }}>
            <li style={{ padding: '0.3rem 0' }}>POST /api/auth/register</li>
            <li style={{ padding: '0.3rem 0' }}>POST /api/auth/login</li>
            <li style={{ padding: '0.3rem 0' }}>GET /api/auth/me</li>
            <li style={{ padding: '0.3rem 0' }}>GET /api/sites</li>
            <li style={{ padding: '0.3rem 0' }}>POST /api/sites</li>
            <li style={{ padding: '0.3rem 0' }}>POST /api/sites/[id]/chat</li>
            <li style={{ padding: '0.3rem 0' }}>GET /api/sites/[id]/preview/[changeId]</li>
            <li style={{ padding: '0.3rem 0' }}>POST /api/sites/[id]/approve/[changeId]</li>
            <li style={{ padding: '0.3rem 0' }}>POST /api/sites/[id]/reject/[changeId]</li>
            <li style={{ padding: '0.3rem 0' }}>GET /api/sites/[id]/history</li>
          </ul>
        </div>

        <p style={{ color: '#666', fontSize: '0.85rem' }}>
          Use the iOS app to interact with this API
        </p>
      </main>
    </div>
  );
}
