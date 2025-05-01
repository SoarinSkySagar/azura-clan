export default function Hero() {
  return (
    <section className="relative min-h-screen overflow-hidden font-inter">
      <svg
        className="absolute inset-0 w-full h-full"
        viewBox="0 0 1440 615"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        preserveAspectRatio="none"
      >
        <path
          d="M0 0H1440C1440 0 1440 588 1440 611C1440 634 211.507 514.872 0 611V0Z"
          className="fill-bg-light-gray"
        />
      </svg>

      <div className="relative z-10 flex flex-col items-center justify-center px-4 md:px-8 lg:px-16 min-h-screen">
        <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold text-center mb-4">
          LEAD YOUR CLAN TO GLORY
        </h1>
        <p className="text-xl md:text-2xl text-muted-text mb-8 text-center">
          Unite, Battle, Conquer. The Azura Universe Awaits
        </p>
        <button className="bg-button-bg hover:bg-button-hover text-button-text font-medium py-3 px-8 rounded-full transition-colors duration-300 text-lg">
          Create or Join Clan
        </button>
      </div>
    </section>
  );
}
