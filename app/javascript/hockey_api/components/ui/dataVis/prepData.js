
function getUnitData(item, index, units) {
  // sample data for one unit
  // [ // unit games (each w/ plus-minus)
  //        { plusMinus:
  //           [ {ordinal: 1, fraction: 1},
  //             {ordinal: 2, fraction: 0.5, per60Fraction: 0.5},
  //        { plusMinus:
  //             {ordinal: 3, fraction: 1},
  //             {ordinal: 4, fraction: 0.3, per60Fraction: 0.5} ] },
  //   ]

  const unit = units[index];
  var unitData = [];

  // using absolute values
  const plusMinus = unit.tallies.plus_minus;
  const plusMinus_Abs = Math.abs(plusMinus);
  const pMSign = plusMinus/plusMinus_Abs;
  const plusMinusPer60 = plusMinus_Abs / (unit.tallies.TOI / 3600);
    const plusMinusPerGame = +plusMinusPer60.toFixed(3);

    const games = Math.ceil(unit.tallies.TOI / 3600);
    const lastGame_plusMinus = +(plusMinus_Abs % plusMinusPer60);
    const per60Fraction = +( plusMinusPerGame -
      Math.floor(plusMinusPerGame) );

  var game_plusMinus = plusMinusPerGame;
  var i;
  unitData = {
    //d3's #enter() uses arrays to indicate the appending of an element
    info: [{
        players: [unit.players],
        plusMinusTotal: [plusMinus],
        per60: [plusMinusPer60] }],
    games: [[]] };

  for (i = 1; i <= games; i++) {
    if ( i == games ) { game_plusMinus = lastGame_plusMinus; }
    unitData.games[0][i] = {};
    unitData.games[0][i].plusMinus = [];

    var n;
    var fraction = 1;
    // SET FRACTION
    // if 'n' equals last iteration, set 'fraction' to remaining decimal
    for (n = 1; n <= Math.ceil(plusMinusPerGame); n++) {
      let g_pMCeil = Math.ceil(game_plusMinus);
      var per60Fraction_data = null;
      let pMP60Ceil = Math.ceil(plusMinusPer60);
      let remainder = +( game_plusMinus - Math.floor(game_plusMinus) );
      // LAST PER60: plusMinusPer60 marks the total plus-minus capacity (per60)
      if ( n == pMP60Ceil && per60Fraction > 0 ) {
        per60Fraction_data = per60Fraction; }
      // LAST pM: if on last scored plus-minus
      if ( n == g_pMCeil && remainder > 0 ) {
        fraction = remainder;
        // per60Fraction indicates fraction-presence to renderPlusMinus()
        if ( n < pMP60Ceil ){
          // here, per60Fraction_data should = 1 until LAST PER60
          per60Fraction_data = 1; } }
      // OVER pM: if for-loop (n) over scored plus-minus, yet under capacity
      else if ( n > g_pMCeil ) {
        fraction = 0; }

      unitData.games[0][i].plusMinus.push({
        ordinal: n,
        fraction: +fraction.toFixed(3) * pMSign
      })
      if (per60Fraction_data !== null) {
        unitData.games[0][i].plusMinus.slice(-1)[0].per60Fraction = per60Fraction_data * pMSign; }
    }
  } //for loops

  return unitData;
}

function applyFractionArray(unit) {
  for (let i=1; i < unit.games[0].length; i++) {

  const plusMinus = unit.games[0][i].plusMinus;
  for(let n = 0; n < plusMinus.length; n++ ) {
    const fraction = Math.abs( plusMinus[n].fraction );
    // instances including a per60Fraction, will always exhibit fraction < 1
    const per60Fraction = Math.abs( plusMinus[n].per60Fraction );
    const fractionFraction = Math.abs(fraction - fraction.toFixed(1));

    if (per60Fraction && fraction < 1) {
      let per60Remainder = per60Fraction - fraction;
      if (fractionFraction > 0) {
        per60Remainder = Math.floor(per60Remainder * 10); }
      else {
        per60Remainder = Math.ceil(per60Remainder * 10); }

      plusMinus[n].fractionArray =
        Array.from({length: Math.ceil(fractionFraction)}, () => ({name: 'pMF', value: fractionFraction }) )
        .concat(Array.from({length: fraction * 10}, () => 'pMF'))
        .concat(Array.from({length: per60Remainder }, () => 'per60'));
    } }}
}


export default { getUnitData, applyFractionArray }
