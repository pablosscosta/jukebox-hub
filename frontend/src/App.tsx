import { Route, Routes } from 'react-router';
import { AuthCallbackPage } from './pages/AuthCallbackPage';
import { GuestPage } from './pages/GuestPage';
import { HomePage } from './pages/HomePage';
import { HostPage } from './pages/HostPage';

function App() {
  return (
    <Routes>
      <Route path="/" element={<HomePage />} />
      <Route path="/auth/callback" element={<AuthCallbackPage />} />
      <Route path="/host" element={<HostPage />} />
      <Route path="/p/:partyId" element={<GuestPage />} />
    </Routes>
  );
}

export default App;
