#[derive(Clone, Drop, Serde, starknet::Store)]
pub struct Clan {
    pub name: ByteArray,
    pub symbol: ByteArray,
}
