


const GameRow = ({teams}) => {
  let rows

  // may move to Day component for additional sort control
  const teamKeys = Object.keys(teams)
  if (
    !( teamKeys
       .some( teamKey => teams[teamKey].powerScore === undefined ) )
  ) { teamKeys.sort( (a, b) =>
        teams[b].powerScore.scores.powerScore - teams[a].powerScore.scores.powerScore ) }

  rows =
  teamKeys
  .map( (teamKey, index) => {
    const team = teams[teamKey]
    // previous and subsequent days -- placeholders
    if (team.powerScore === undefined || team === undefined) {
        return (
          <div key={index} id={teamKey}
              className={`row ${team.result}`}>
            <div className="data-element title">{team.name}</div>
            <div className="data-element data">{team.score}</div>
          </div> )
    }
    else {
      const scores = team.powerScore.scores
      const powerScores =
        <React.Fragment>
          <div className="percentages data-element data">
            {scores.pointsPercentageLatest}</div>
          <div className="percentages data-element data">
            {scores.pointsPercentagePrior}</div>
          <div className="powerScore data-element data">
            {scores.powerScore}</div>
        </React.Fragment>

      return (
        <div key={index} id={team.powerScore.name}
            className={`row ${team.result}`}>
          <div className="data-element title">{team.name}</div>
          <div className="data-element data">{team.score}</div>
          {powerScores}
        </div> )
        }
    }) // map

  return(
    <div className="gameRow">
      {rows}</div>
  )
}

export default GameRow
