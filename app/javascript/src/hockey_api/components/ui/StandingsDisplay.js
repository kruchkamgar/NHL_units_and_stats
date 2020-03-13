import React from 'react';
import StandingRow from './StandingRow';

const StandingsDisplay = ({
  standings = [],
  getStandings = f=>f,
  fetching = false
 }) => {

  if(standings.length === 0) { getStandings() }

  const standingsRows =
    standings
    .map( (standing, index) => {
      return <StandingRow key={index} standing={standing}/>
    })

  console.log("standings", standings);
  console.log("rows", standingsRows);

  return(
    <div className="standings chart">
      <table>
        <tbody>
        {standingsRows}</tbody>
      </table>
    </div>
  )
}

export default StandingsDisplay

// LOGOS-
// http://www-league.nhlstatic.com/images/logos/teams-current-primary-dark/${teamId}.svg
