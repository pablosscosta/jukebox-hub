import { render, screen } from '@testing-library/react';
import App from './App';

describe('App', () => {
  it('shows the product name to the visitor', () => {
    render(<App />);

    expect(screen.getByRole('heading', { name: 'Jukebox Hub' })).toBeInTheDocument();
  });
});
