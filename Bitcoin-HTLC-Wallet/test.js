const Client = require('bitcoin-core');
const client = new Client({username: 'bitcoin', password: 'local321', network: 'testnet'})

const txHex = '01000000012e3d478c6db966e137ecbe1a3827e8d0ee6fa09a4cb65272b7667009330a7673000000006c483045022100e90aa47f1ba4d6395ff687f3ae12e4659783e65d95392448e04d815a160ea5b9022023a31943d72f7c6a5170d0d645d8d423d435bb95377b864c1e7d6a48a99fadab0121037d8e7d464f8d9ea0e8c65e66c6d8203e8614b4964a23149d237f0438e6cc77e4000000000001583e0f00000000001976a91437decfcf9c6e8a58ffdd62b4983bcb7549979ef188accbbce45a'

client.sendRawTransaction(txHex, (error, response) => {
  if (error) console.log(error);
  console.log(response);
});