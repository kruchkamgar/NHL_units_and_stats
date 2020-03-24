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

  // use to determine, when next to fetch
  const [trackRange, setTrackRange] = useState(5);
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
            name: team.name, // allow matching between schedule data and powerScores analytics
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
    setTimeMark( prevTimeMark => {
      // direction = compareTimeMarks(prevTimeMark)
      return addDays(prevTimeMark, direction) })

    // setGames( gamesByDates(newGames) );
  }

  const previousDay = <Day games={games[0]} scores={false}/>;
  const nextDay = <Day games={games[2]} scores={false}/>;
  //

  return (
    <div className="wrapper d-flex">
      <div className="queued chart" onClick={ ()=>
        handleDateChange(-1)}>{previousDay}</div>
      <div className="queue chart">
        <Day games={games[1]} scores={powerScoresByDate[1]}/></div>
      <div className="queued chart" onClick={ ()=>
        handleDateChange(1)}>{nextDay}</div>
    </div>
  )
}

export default PowerScoresDisplay

// LOGOS-
// http://www-league.nhlstatic.com/images/logos/teams-current-primary-dark/${teamId}.svg
