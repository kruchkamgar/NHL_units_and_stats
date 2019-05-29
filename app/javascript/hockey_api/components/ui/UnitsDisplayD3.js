import React, { useState, useEffect } from 'react';
import * as d3 from "d3";

import PropTypes from 'prop-types';
import { Link } from 'react';

import Axes from './Axes';
import UnitRow from './UnitRow';

import '../../stylesheets/UnitsDisplay.scss'

function UnitsDisplay ({ units=[], clearUnits=f=>f, loadTeamUnits=f=>f, fetching=false }) {

  const [value, setValue] = useState({/* initial values */
    keys: ["apples", "bananas", "cherries"],
    data: [
      { month: "Q1-2017", apples: 300, bananas: 500, cherries: 700, total: 1500 },
      { month: "Q2-2017", apples: 500, bananas: 400, cherries: 1000, total: 1900 },
      { month: "Q3-2017", apples: 700, bananas: 200, cherries: 500, total: 1400 },
      { month: "Q4-2017", apples: 300, bananas: 700, cherries: 200, total: 1200 },
      { month: "Q1-2018", apples: 300, bananas: 700, cherries: 200, total: 1200 },
      { month: "Q2-2018", apples: 500, bananas: 400, cherries: 1000, total: 1900 },
      { month: "Q3-2018", apples: 300, bananas: 500, cherries: 700, total: 1500 } ]
  });

  // recreate scales upon updated data
  useEffect(() => {
    setValue({
      /*colors: d3.scaleOrdinal(d3.schemeCategory10),*/
      ...value,
      colors: d3.scaleOrdinal(d3.schemeCategory10),
      scaleX: createScaleX(),
      scaleY: createScaleY()
    });
  }, [value]);

    let team_number
    const query_submit = e => {
      e.preventDefault()
      loadTeamUnits( team_number.value )
    }

    function createScaleX() {
     return d3.scaleBand()
       .domain(value.data.map(d => d.month))
       .range([0, 700])
       .padding(0.1);
    }

    function createScaleY() {
      const yValues = value.data.map(d => d.total);

      return d3.scaleLinear()
       .domain([0, d3.max(yValues)])
       .range([350, 0]);
    }

    function renderStacks(stack) {
      const { colors, scaleX, scaleY } = value;
      return (
        <g key={stack.key} fill={colors(stack.key)} >
          {stack.map(d => {
            const height = scaleY(d[0]) - scaleY(d[1]);
            return (
              <rect key={String(d.data.month)}
                x={scaleX(d.data.month)}
                y={scaleY(d[1])}
                width={scaleX.bandwidth()}
                height={height}>
                  <title>{stack.key}: {d.data[stack.key]}</title>
              </rect> );
          })}
        </g>
      );
    }

    const width = 800;
    const height = 400;
    const { scaleX, scaleY } = value;
    const series =
    d3.stack().keys(value.keys)(value.data);
    // const { width, height } = this.props;

    return (
        <div className="units-wrapper">
              <div className="unload">
                <button type="button" onClick={() => clearUnits()}>Clear Units</button>
              </div>
          <form onSubmit={query_submit} className="query">
              <label htmlFor="team">Team number</label>
              <input id="team" type="number" step="1" min="1"
                     ref={input => team_number = input}/>
              <button>load units</button>
          </form>

        { (!scaleX || !scaleY) ?
            <div>Loading...</div> :
            <svg width={width} height={height} className="bar-chart bar-chart--stack">
              <g /*transform=`translate(${MARGINS.left},${MARGINS.top})`*/>
                <Axes scaleX={scaleX} scaleY={scaleY} />
              </g>
              <g /* transform=`translate(${MARGINS.left},${MARGINS.top})`*/>
                {series
                  .map(
                    (s) => renderStacks(s) )}</g>
            </svg> }
      </div> /*units-list*/
    )
} //UnitsDisplay

UnitsDisplay.propTypes = {

}

export default UnitsDisplay
