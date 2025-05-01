import ClanCards from "@/components/ClanCards";
import Features from "@/components/Features";
import Footer from "@/components/Footer";
import Hero from "@/components/Hero";
import Navbar from "@/components/Navbar";

export default function Home() {
  return (
    <>
      <Navbar />
      <Hero />
      <Features />
      <ClanCards />
      <Footer />
    </>
  );
}
