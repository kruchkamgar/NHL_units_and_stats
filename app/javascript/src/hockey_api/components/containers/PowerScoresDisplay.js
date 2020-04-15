import PowerScoresDisplay from '../ui/PowerScoresDisplay'
import { connect } from 'react-redux'

import { scheduleAndPowerScores } from '../../actions'

const mapStateToProps = (state) =>
  ({
    powerScoresByDate: state.powerScores.powerScores,
    schedule: state.powerScores.schedule,
    scheduleDates: state.powerScores.scheduleDates,
    fetching: state.powerScores.fetching
  })


const mapDispatchToProps = dispatch => {
    return {
      getScheduleAndPowerScores: (date, storeSchedule=true) => dispatch(scheduleAndPowerScores(date, storeSchedule))
    }
  }

export default connect(mapStateToProps, mapDispatchToProps)(PowerScoresDisplay)
