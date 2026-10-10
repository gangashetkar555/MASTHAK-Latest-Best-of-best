import '@fontsource/fraunces/500.css';
import '@fontsource/fraunces/400-italic.css';
import '@fontsource/nunito/400.css';
import '@fontsource/nunito/700.css';
import type { Metadata } from 'next';
import { Navigation, Footer } from '@/components/Shell';
import './globals.css';
import './experience.css';
import './cinematic.css';
import './journey.css';
import './restored-ui.css';
export const metadata: Metadata = { title: 'MASTHAK — Everything Is Not Garbage', description: 'Step into the Garbage Court. Read the story, explore material lifetimes, and play your way to better waste choices.' };
export default function RootLayout({ children }: { children: React.ReactNode }) { return <html lang="en"><body><a className="skip" href="#main">Skip to content</a><Navigation/><main id="main">{children}</main><Footer/></body></html>; }




