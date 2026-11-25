import { useEffect, useState } from 'react';

type Props = { startedAt: string; durationMs: number };

function formatTime(ms: number) {
  const totalSeconds = Math.floor(ms / 1000);
  const seconds = String(totalSeconds % 60).padStart(2, '0');
  return `${String(Math.floor(totalSeconds / 60))}:${seconds}`;
}

// How far the song is, worked out from when it started: no extra calls to the API. It doesn't know
// about pauses on Spotify, so it's an estimate; it stops at the end of the song.
export function ProgressBar({ startedAt, durationMs }: Props) {
  const [now, setNow] = useState(() => Date.now());

  useEffect(() => {
    const timer = setInterval(() => {
      setNow(Date.now());
    }, 1000);
    return () => {
      clearInterval(timer);
    };
  }, []);

  const elapsed = Math.min(Math.max(now - Date.parse(startedAt), 0), durationMs);
  const percent = durationMs > 0 ? Math.round((elapsed / durationMs) * 100) : 0;

  return (
    <div className="progress">
      <div
        className="progress-track"
        role="progressbar"
        aria-label="Progresso da música"
        aria-valuemin={0}
        aria-valuemax={100}
        aria-valuenow={percent}
      >
        <div className="progress-fill" style={{ width: `${String(percent)}%` }} />
      </div>
      <div className="progress-times">
        <span>{formatTime(elapsed)}</span>
        <span>{formatTime(durationMs)}</span>
      </div>
    </div>
  );
}
