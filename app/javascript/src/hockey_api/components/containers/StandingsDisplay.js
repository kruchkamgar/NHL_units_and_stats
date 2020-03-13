import StandingsDisplay from '../ui/StandingsDisplay'
import { connect } from 'react-redux'

import { standings } from '../../actions'

const mapStateToProps = (state) =>
  ({
    standings: state.standings.standings,
    fetching: state.standings.fetching
  })


const mapDispatchToProps = dispatch => {
    return {
      getStandings: () => dispatch(standings())
    }
  }

export default connect(mapStateToProps, mapDispatchToProps)(StandingsDisplay)
