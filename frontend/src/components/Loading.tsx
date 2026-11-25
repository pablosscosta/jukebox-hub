import { useEffect, useState } from 'react';

// After this long, the wait is probably the API waking up (on the free plan it sleeps when nobody
// uses it), not a slow network.
export const WAKE_UP_HINT_DELAY_MS = 4000;

// A loading message that, when the wait gets long, explains why.
export function Loading({ text }: { text: string }) {
  const [slow, setSlow] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => {
      setSlow(true);
    }, WAKE_UP_HINT_DELAY_MS);
    return () => {
      clearTimeout(timer);
    };
  }, []);

  return (
    <div aria-live="polite">
      <p className="hint">{text}</p>
      {slow && (
        <p className="hint">
          O servidor estava dormindo e está acordando. Na primeira visita isso pode levar até 1
          minuto.
        </p>
      )}
    </div>
  );
}
