import { render } from '@testing-library/react';
import { MemoryRouter } from 'react-router';
import App from '../App';

// Renders the whole app at a given URL, so tests exercise the real routes.
export function renderAt(path: string) {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <App />
    </MemoryRouter>,
  );
}

// Replaces fetch with a mock that answers with the given responses, in order.
export function mockFetch(...responses: Array<{ status: number; body?: unknown }>) {
  const fetchMock = vi.fn();
  for (const { status, body } of responses) {
    fetchMock.mockResolvedValueOnce(
      new Response(body === undefined ? null : JSON.stringify(body), {
        status,
        headers: { 'Content-Type': 'application/json' },
      }),
    );
  }
  vi.stubGlobal('fetch', fetchMock);
  return fetchMock;
}
