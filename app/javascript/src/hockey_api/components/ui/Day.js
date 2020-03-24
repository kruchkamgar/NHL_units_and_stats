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
      const keyTeam = game.teams[key]
      teams[key] = {}
      teams[key].score = keyTeam.score
      teams[key].name = keyTeam.team.name
      // - match the game teams with powerScore teams
      if(scores){
        Object.assign(
          teams[key],
          {powerScore:
            scores.find( score =>
              keyTeam.team.name === score.name ) }
        ) }
    })
    // result of game (scores)
    // - function to determine the winner
    if (teams.away.score > teams.home.score) {
      Object.assign(teams.away, {result: "winner"}); }
    else if (teams.away.score < teams.home.score) {
      Object.assign(teams.home, {result: "winner"}); }

    return <GameRow key={index} teams={teams}/>
  }) // map

    // - game table data functions (pass winner/loser)


  return (
    <div className="powerScores">
      <div>
        {gameRows}
      </div>
    </div>
  )
}

export default Day
