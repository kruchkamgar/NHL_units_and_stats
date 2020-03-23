import Day from './Day';
import { useState, useEffect } from 'react';

import { gameDates, gamesByDates, addDays, dateString } from 'src/hockey_api/lib/dates';

const PowerScoresDisplay = ({
  powerScores = [],
  schedule = [],
  scheduleDates = [],
  getScheduleAndPowerScores = f=>f,
  fetching = false
}) => {

  const today = dateString(new Date());
  const [timeMark, setTimeMark] = useState("2020-03-04");
  // could put condition in action creator
  if(!fetching && (
    powerScores.length === 0 || schedule.length === 0 ||
    direction == 1) ) getScheduleAndPowerScores(timeMark);

  const [dates, setDates] = useState();

  let direction = 0;
  const [games, setGames] = useState({
    previous: [], day:[], subsequent:[]
  });
  const [powerScoresByDate, setPowerScoresByDate] = useState([]);

useEffect( ()=> {
  if(scheduleDates.length > 0){
    // days based on schedule
    setDates(
      gameDates(scheduleDates, timeMark, direction) );
  }
}, [timeMark, scheduleDates]); // useEffect

useEffect( ()=> {
  if(!(dates === undefined)){
    // find the latest powerScores using the timeMark
    setPowerScoresByDate(
      Object.keys(dates)
      .map( key => {
        return powerScores
        .map( team =>{
          return {
            name: team.name,
            scores: team.scores
              .find( score => score.asOfDate <= dates[key] ) }
        }) })
    )

    // - function to collect games from schedule matching the date
    setGames( prevGames=>{
      return gamesByDates(prevGames, dates, schedule, direction)
    });
  } //if
}, [dates])

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
