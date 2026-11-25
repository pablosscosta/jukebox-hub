import { act, render, screen } from '@testing-library/react';
import { Loading, WAKE_UP_HINT_DELAY_MS } from './Loading';

describe('Loading', () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it('explains a long wait: the server may be waking up', () => {
    vi.useFakeTimers();
    render(<Loading text="Carregando..." />);

    expect(screen.getByText('Carregando...')).toBeInTheDocument();
    expect(screen.queryByText(/está acordando/)).not.toBeInTheDocument();

    act(() => {
      vi.advanceTimersByTime(WAKE_UP_HINT_DELAY_MS);
    });

    expect(screen.getByText(/está acordando/)).toBeInTheDocument();
  });
});
