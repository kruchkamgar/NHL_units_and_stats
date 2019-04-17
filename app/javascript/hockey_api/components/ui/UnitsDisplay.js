import PropTypes from 'prop-types';
import { Link } from 'react'
import UnitRow from './UnitRow'
// import Terrain from 'react-icons/md/terrain'
// import SnowFlake from 'react-icons/ti'
import '../../stylesheets/UnitsDisplay.scss'

const UnitsDisplay = ({ units=[], loadUnits=f=>f, clearUnits=f=>f, loadTeamUnits=f=>f, fetching=false }) => {

    const activeFilterStyle = {
        textDecoration: 'none',
        color: 'black'
    }

    let team_number

    const query_submit = e => {
      e.preventDefault()
      loadTeamUnits( team_number.value )
    }

    return (
        <div className="units_wrapper">
              <div className="load">
                <button type="button" onClick={() => loadUnits()}>Load Units</button>
              </div>
              <div className="unload">
                <button type="button" onClick={() => clearUnits()}>Clear Units</button>
              </div>
          <form onSubmit={query_submit} className="query">
              <label htmlFor="team">Team number</label>
              <input id="team" type="number" step="1" min="1"
                     ref={input => team_number = input}/>
              <button>load units</button>
          </form>
          <div className="units-list">
            <table>
              {/* <caption>double click to remove</caption> */}
                <thead>
                <tr>
                    <th>units</th>
                    <th>plus-minus</th>
                    <th>{/* */}</th>
                    <th></th>
                </tr>
                <tr>
                    {/* <td colSpan={4}>
                        <Link to="/list-days">All Days</Link>
                        <Link to="/list-days/powder" activeStyle={activeFilterStyle}>Powder Days</Link>
                        <Link to="/list-days/backcountry" activeStyle={activeFilterStyle}>Backcountry Days</Link>
                    </td> */}
                </tr>
                </thead>
                <tbody>
                { units.map((unit, i) =>
                    <UnitRow key={i} {...unit} html_id={"row" + i} />
                ) }
                </tbody>
            </table>
          </div> {/*units-list*/}
        </div>
    )
}

UnitsDisplay.propTypes = {

}

export default UnitsDisplay
