import React, { useState, useEffect } from 'react';

import prepData from './dataVis/prepData.js'
import renderPlusMinus from './dataVis/renderD3.js'

import PropTypes from 'prop-types';
import { Link } from 'react';

// import Axes from './Axes';
// import UnitRow from './UnitRow';

import '../../stylesheets/UnitsDisplay.scss'

function UnitsDisplay({
  units = [],
  clearUnits = f => f,
  loadTeamUnits = f => f,
  fetching = false
}) {

  useEffect(() => {
    renderPlusMinus(data_prepped);
  });

  const unitsData = units.map( prepData.getUnitData );

  const data_prepped = unitsData.slice(0);
  data_prepped.forEach(prepData.applyFractionArray);

  // var unitsWrapperRef;

    let team_number
    const query_submit = e => {
      e.preventDefault()
      loadTeamUnits(team_number.value)
    }

    return (
      <div id="units-wrapper wrapper grid">
        <form onSubmit={ query_submit } className="query">
          <label htmlFor="team">Team number</label>
          <input id="team" type="number" step="1" min="1"
            ref={input => team_number = input } />
          <button>load units</button>
          <button type="button" onClick={() => clearUnits() }>
            clear units </button>
        </form>

        <div className="data-labels info">
          <div className="players">players</div>
          <div className="per60Info">
            <div>per 60</div>
            <div className="ancillary-label">[projected] efficiency</div>
          </div>
          <div className="plusMinusTotal"><span sign="1">plus</span><span sign="-1">minus</span></div>
        </div>
      </div>
    )
  } //UnitsDisplay

  UnitsDisplay.propTypes = {
    units: PropTypes.array.isRequired
  }

  export default UnitsDisplay
