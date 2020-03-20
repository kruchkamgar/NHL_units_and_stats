import GameRow from './GameRow.js';

const Day = ({
  scores = [],
  games = []
}) => {

// sort function for columns of the day component
// gameTableFunctions:
// - calculate surprise (powerScore differential)
// - calculate combined power
// - calc performance jump

  const gameRows =
  games
  .map( (game, index) =>{

    const teams = {}
    Object.keys(game.teams)
    .forEach( key => {
      teams[key] = {}
      teams[key].score = game.teams[key].score
      // - match the game teams with powerScore teams
      if(scores){
        Object.assign(
          teams[key],
          {powerScores:
            scores.find( score =>{
              teams[key].team.name === score.name }) }
        ) }
    })
    // result of game (scores)
    // - function to determine the winner
    if (teams.away > teams.home) {
      Object.assign(teams.away, {result: "winner"}); }
    else if (teams.home > teams.away) {
      Object.assign(teams.home, {result: "winner"}); }

    return <GameRow key={index} teams={teams}/>
  }) // map

    // - game table data functions (pass winner/loser)

  // const powerScoresRows =
  //   powerScoresDay
  //   .map( (powerScore, index) => {
  //     return <PowerScoreRow key={index} powerScore={powerScore}/>
  //   })

  return (
    <div className="powerScores chart">
      <table>
        <tbody>
        {gameRows}</tbody>
      </table>
    </div>
  )
}

export default Day
