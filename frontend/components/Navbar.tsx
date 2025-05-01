"use client";

import { useTheme } from "@/hooks/useTheme";
import { Menu, Moon, Sun, X } from "lucide-react";
import { useState } from "react";

export default function Navbar() {
  const { theme, toggleTheme } = useTheme();
  const [isNavOpen, setIsNavOpen] = useState(false);

  const handleNavToggle = () => {
    setIsNavOpen(!isNavOpen);
  };

  return (
    <nav className="flex justify-between items-center p-4 bg-[#E5E5E5] dark:bg-black font-inter fixed inset-x-0 z-50">
      <h2 className="text-2xl md:text-4xl font-bold">Azura</h2>
      <div
        className={`flex gap-4 max-sm:fixed max-sm:flex-col max-sm:justify-center max-sm:items-center max-sm:inset-0 max-sm:top-0 max-sm:w-full max-sm:h-[60vh] max-sm:transform max-md:transition-transform max-md:duration-300 max-sm:-z-[5] ${
          isNavOpen
            ? "translate-y-0 opacity-100 max-sm:backdrop-blur-md"
            : "max-sm:-translate-y-[1000%]"
        }`}
      >
        <button className="bg-button-bg text-button-text px-7 py-2 rounded-xl cursor-pointer max-sm:text-sm max-sm:w-full max-sm:max-w-xs hover:bg-button-hover ">
          Login
        </button>
        <button className="bg-button-bg text-button-text px-4 py-2 rounded-xl cursor-pointer max-sm:text-sm max-sm:w-full max-sm:max-w-xs hover:bg-button-hover">
          Connect Wallet
        </button>
        <button onClick={toggleTheme} className="cursor-pointer">
          {theme === "dark" ? <Moon /> : <Sun />}
        </button>
      </div>
      <button className="hidden max-sm:flex" onClick={handleNavToggle}>
        {isNavOpen ? <X size={24} /> : <Menu size={24} />}
      </button>
    </nav>
  );
}
