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

type MockResponse = { status: number; body?: unknown };

// Replaces fetch with a fake API keyed by "METHOD /path". A list of responses is used in order,
// and the last one keeps answering after that. Unknown routes fail the test loudly.
export function mockApi(routes: Record<string, MockResponse | MockResponse[]>) {
  const calls: Record<string, number> = {};
  const fetchMock = vi.fn((url: string, init: RequestInit = {}) => {
    const route = `${init.method ?? 'GET'} ${new URL(url).pathname}`;
    const responses = [routes[route] ?? []].flat();
    if (responses.length === 0) throw new Error(`Unexpected request: ${route}`);

    const callCount = calls[route] ?? 0;
    calls[route] = callCount + 1;
    const { status, body } = responses[Math.min(callCount, responses.length - 1)] as MockResponse;
    return Promise.resolve(
      new Response(body === undefined ? null : JSON.stringify(body), {
        status,
        headers: { 'Content-Type': 'application/json' },
      }),
    );
  });
  vi.stubGlobal('fetch', fetchMock);
  return fetchMock;
}
