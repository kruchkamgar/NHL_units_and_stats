import Day from './Day';
import { useState, useEffect } from 'react';

import { gameDates, gamesByDates, addDays } from 'src/hockey_api/lib/dates';

const PowerScoresDisplay = ({
  powerScores = [],
  schedule = [],
  scheduleDates = [],
  getScheduleAndPowerScores = f=>f,
  fetching = false
}) => {

  // could put condition in action creator
  if(!fetching && (powerScores.length === 0 || schedule.length === 0) ) getScheduleAndPowerScores();

  const today = new Date();

  const [timeMark, setTimeMark] = useState( new Date("2020-03-05") );
  // days based on schedule
  // - function to collect games from schedule matching the date

  const [dates, setDates] = useState();
  const [games, setGames] = useState({
    previous: [], day:[], subsequent:[]
  });
  let direction = 0;

  let powerScoresByDate = []

useEffect( ()=> {
  if(!(dates === undefined)){
    setGames( prevGames=>{
      return gamesByDates(prevGames, dates, schedule, direction)
    });

    // find the latest powerScores using the timeMark
    powerScoresByDate =
    Object.keys(dates)
    .map( key => {
      powerScores
      .map( team =>{
        return team.scores
          .find( score =>{
            Number(new Date(score.asOfDate) <= Number(dates[key]) )}
          )
    }) })
  }
}, [dates])

useEffect( ()=> {
  if(scheduleDates.length > 0){
    const gameDs = gameDates(scheduleDates, timeMark, direction)
    setDates( gameDs );
  }
}, [timeMark, scheduleDates]); // useEffect

  // setGames( gamesByDate(schedule, timeMark) );

  // render previous and next days [logic to store them as variables]

  // const compareTimeMarks =
  // (prevTimeMark) => {
  //   let direction = 0;
  //   if (prevTimeMark < timeMark) direction = 1;
  //   if (prevTimeMark > timeMark) direction = -1;
  //   return direction;
  // }

  // - click handler function to move between days
  const handleDateChange =
  (_direction) => {
    direction = _direction;
    // let newDay = null, newGames = null;

    setTimeMark( prevTimeMark => {
      // direction = compareTimeMarks(prevTimeMark)
      return addDays(prevTimeMark, direction) })

    setGames( gamesByDate(newGames) );
  }

  const previousDay = <Day games={games[0]} scores={false}/>;
  const nextDay = <Day games={games[2]} scores={false}/>;
  //

  return (
    <React.Fragment>
      <div className="queued">{previousDay}</div>
      <Day games={games[1]} scores={powerScoresByDate[1]}/>
      <div className="queued">{nextDay}</div>
    </React.Fragment>
  )
}

export default PowerScoresDisplay

// LOGOS-
// http://www-league.nhlstatic.com/images/logos/teams-current-primary-dark/${teamId}.svg
