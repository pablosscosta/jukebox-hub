import { Route, Routes } from 'react-router';
import { AuthCallbackPage } from './pages/AuthCallbackPage';
import { HomePage } from './pages/HomePage';
import { HostPage } from './pages/HostPage';

function App() {
  return (
    <Routes>
      <Route path="/" element={<HomePage />} />
      <Route path="/auth/callback" element={<AuthCallbackPage />} />
      <Route path="/host" element={<HostPage />} />
    </Routes>
  );
}

export default App;
