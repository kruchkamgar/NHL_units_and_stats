import UnitsDisplay from '../ui/UnitsDisplay'
import { connect } from 'react-redux'
import { clearUnits, teamUnits } from '../../actions'

const mapStateToProps = (state) =>
  ({
    units: state.allUnits.units,
    fetching: state.allUnits.fetching
    // filter: props.params.filter,
  })

const mapDispatchToProps = (dispatch) =>
  ({
    clearUnits() {
      dispatch(
        clearUnits() )
    },
    loadTeamUnits(teamNumber) {
      if (!store.getState().allUnits.fetching){
        dispatch(
          teamUnits(teamNumber) ) }
    }
  })

export default connect(mapStateToProps, mapDispatchToProps)(UnitsDisplay)
