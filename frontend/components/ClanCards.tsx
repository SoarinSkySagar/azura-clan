interface Clans {
  name: string;
  noOfMembers: number;
  rank: number;
}

const clans: Clans[] = [
  {
    name: "Phoenix Rising",
    noOfMembers: 24,
    rank: 1,
  },
  {
    name: "Shadow Wolves",
    noOfMembers: 31,
    rank: 2,
  },
  {
    name: "Frost Giants",
    noOfMembers: 28,
    rank: 3,
  },
];

export default function ClanCards() {
  return (
    <section className="bg-section-bg flex flex-col justify-center items-center mt-10 py-16 space-y-10 font-inter">
      <h2 className="text-3xl md:text-5xl font-bold">Clan Cards</h2>
      <div className="flex flex-wrap justify-center items-stretch gap-7">
        {clans.map((clan) => (
          <div
            key={clan.rank}
            className="bg-card-bg w-72 flex px-4 py-6 rounded-2xl space-x-3"
          >
            <span className="block w-16 h-16 rounded-full bg-white shrink-0"></span>
            <div className="flex flex-col justify-between">
              <div className="space-y-2">
                <p className="font-bold text-xl">{clan.name}</p>
                <p className="text-sm">Members: {clan.noOfMembers}</p>
              </div>
              <button className="py-2 px-3 rounded-full text-white font-bold bg-black w-fit mt-3">
                Rank #{clan.rank}
              </button>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
