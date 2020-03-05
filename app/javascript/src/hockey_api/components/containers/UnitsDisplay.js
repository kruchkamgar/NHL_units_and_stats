import UnitsDisplay from '../ui/UnitsDisplay'
import { connect } from 'react-redux'
import { units, clearUnits, team_units } from '../../actions'

const mapStateToProps = (state) =>
  ({
    units: state.allUnits.units,
    fetching: state.allUnits.fetching
    // filter: props.params.filter,
  })

const mapDispatchToProps = dispatch =>
  ({
    loadUnits() {
        dispatch(
          units() )
    },
    clearUnits() {
      dispatch(
        clearUnits() )
    },
    loadTeamUnits(team_number) {
      if (!state.standings.fetching){
        dispatch(
          team_units(team_number) ) }
    }
  })



export default connect(mapStateToProps, mapDispatchToProps)(UnitsDisplay)
