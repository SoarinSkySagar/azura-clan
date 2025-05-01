interface Features {
  title: string;
  desc: string;
}

const features: Features[] = [
  {
    title: "Form Clans",
    desc: "Create or join a clan with friends and allies.",
  },
  {
    title: "Battle Together",
    desc: "Strategic Combat for Territory and Resources",
  },
  {
    title: "Climb Ranks",
    desc: "Rise throught Ranks and Earn Exclusive Rewards",
  },
];

export default function Features() {
  return (
    <section className="flex flex-col justify-center items-center space-y-16 my-3 font-inter">
      <h2 className="text-3xl md:text-5xl font-bold">Core Features</h2>
      <div className="flex flex-wrap justify-center items-stretch gap-7">
        {features.map((feature, index) => (
          <div
            className="bg-card-bg w-72 flex  flex-col text-center px-4 py-6 rounded-2xl space-y-3"
            key={index}
          >
            <h3 className="font-bold text-2xl uppercase">{feature.title}</h3>
            <p>{feature.desc}</p>
          </div>
        ))}
      </div>
    </section>
  );
}
