import GameRow from './GameRow.js';

const Day = ({
  dayScores = [],
  games = [],
  date = ""
}) => {

// sort function for columns of the day component
// gameTableFunctions:
// - calculate surprise (powerScore differential)
// - calculate combined power
// - calc performance jump [across requested days, or else on server]

// move to server side?
  const gameRows =
  games
  .map( (game, index) => {

    const teams = {}
    Object.keys(game.teams)
    .forEach( sideKey => {
      const keyTeam = game.teams[sideKey]
      teams[sideKey] = {}
      teams[sideKey].score = keyTeam.score
      teams[sideKey].name = keyTeam.team.name
      // - match the game teams with powerScore teams
      if(dayScores){ // dayScore may equal false
        Object.assign(
          teams[sideKey],
          { ...
            dayScores.powerScores
            .find( scores =>
              keyTeam.team.name === scores.team ) }
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
    <React.Fragment>
      <div className="">{date}</div>
      <div className="powerScores">
        <div>
          {gameRows}
        </div>
      </div>
    </React.Fragment>
  )
}

export default Day
