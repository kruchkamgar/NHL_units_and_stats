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

  const gameRows = <tr><td>gameRows</td></tr>;
  // games
  // .map( game =>{
  //   // game.teams.map ==> row || new game component
  //   // result of game (scores)
  //   // - function to determine the winner
  //   // - game table data functions (pass winner/loser)
  //   // - match the game teams with powerScore teams
  //   teams
  //   .map( team => {
  //     powerScoresDay.find( scores=>{
  //       team.name === scores.name })
  //   })
  //
  //   return <GameRow teams={teams} />
  // })

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
