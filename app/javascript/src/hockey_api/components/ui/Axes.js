import React, { useState, useEffect } from 'react';
import * as d3 from "d3";

import PropTypes from 'prop-types';

function Axes ({ scaleX, scaleY }){

  const axisXRef = React.createRef();
  const axisYRef = React.createRef();

  useEffect(() => {
    createXAxis();
    createYAxis();
  });

  function createXAxis() {
    const xAxis = d3
      .axisTop(scaleX)
      .tickSize(scaleY.range()[0])
      .tickFormat(d => d);

    d3.select(axisXRef.current).call(g => {
      g.call(xAxis);
      g.selectAll(".tick text")
        .attr("y", 20)
        // .classed("chart-axis__label", true)
        // .classed("chart-axis__label--x", true);

      g.selectAll(".tick line")
        .attr("y1", 5)
        // .classed("chart-axis__axis", true);

      // g.selectAll(".domain").classed("chart-axis__axis", true);
    });
  }

  function createYAxis() {
    const yAxis = d3
      .axisRight(scaleY)
      .tickSize(scaleX.range()[1])
      .tickFormat(d => d);

    d3.select(axisYRef.current).call(g => {
      g.call(yAxis);
      g.selectAll(".tick line")
        .attr("x1", -5)
        // .classed("chart-axis__axis", true);

      g.selectAll(".tick text")
        .attr("x", -10)
        // .classed("chart-axis__label", true);

      // g.selectAll(".domain").classed("chart-axis__axis", true);
    });
  }

  return (
   <g className="axis">
     <g ref={axisXRef} transform={`translate(0, ${scaleY.range()[1] - 22.5})`} />
     <g ref={axisYRef} />
   </g>
  )

}

export default Axes
