import * as d3 from "d3";

var renderPlusMinus = function(data_prepped) {
  var unitDataContainer = d3.select("#units-wrapper").select('.unitsData');
    if (typeof unitDataContainer._groups[0][0] == 'undefined'){
      d3.select('#units-wrapper')
      .append('div').attr('class', 'unitsData'); }

  // units divs
    var units = d3.select('.unitsData').selectAll('div.unit').data(data_prepped);

      units.exit().remove();
    var unitsEnter = units.enter()
      .append('div').attr('class', 'unit')
      .attr('sign', function(d){
        let sample = d.games[0][1].plusMinus[0];
        if ( sample ){
          let sample_value = sample.fraction;
        return sample_value/Math.abs(sample_value); }});

    var unitsMerged = unitsEnter.merge(units)
      .data(data_prepped)
      .attr('sign', function(d){
        let sample = d.games[0][1].plusMinus[0];
        if ( sample ){
          let sample_value = sample.fraction;
        return sample_value/Math.abs(sample_value); }});

  /* unit info divs */
    var unitsInfo = unitsMerged.selectAll('.info')
      .data(
        function(d){ return d.info; },
        function(d){ return d.players } );

      unitsInfo.exit().remove();
    var unitsInfoEnter = unitsInfo.enter()
      .insert('div', '.games').attr('class', 'info');

    var unitsInfoMerged = unitsInfoEnter.merge(unitsInfo)
      .data( function(d){ return d.info; });

    var plusMinusTotal = unitsInfoMerged.selectAll('plusMinusTotal');

      plusMinusTotal
        .data(function(d){ return d.plusMinusTotal; })
      .enter()
        .append('div')
        .attr('class', 'plusMinusTotal stats')
        .html(function(d){ return d; });

      plusMinusTotal
        .data(function(d){ return d.plusMinusTotal; })
        .html(function(d){ return d; });

    var per60Info = unitsInfoMerged.selectAll('per60Info');

      per60Info
        .data(function(d){ return d.per60; })
      .enter()
        .append('div')
        .attr('class', 'per60Info stats')
        .html(function(d){ return d.toFixed(2); });

      per60Info
        .data(function(d){ return d.per60; })
        .html(function(d){ return d.toFixed(2); });

    var players = unitsInfoMerged.selectAll('players');

      players
        .data(function(d){ return d.players; })
      .enter()
        .append('div')
        .attr('class', 'players')
        .html(function(d){ return d.join(' &nbsp;.&nbsp; '); });

      players
        .data(function(d){ return d.players; })
        .html(function(d){ return d.join('  '); });

  // games divs (units > containers)
    var unitsGamesContainers = unitsMerged.selectAll('div.games')
      .data( function(d){ return d.games; });

      unitsGamesContainers.exit().remove();
    var unitsGamesContainersEntered = unitsGamesContainers.enter()
      .append('div').attr('class', 'games');
    var unitsGamesContainersMerged = unitsGamesContainersEntered.merge(unitsGamesContainers)
      .data( function(d){ return d.games; });

  // games divs (units > containers > games')
    var unitsGames = unitsGamesContainersMerged.selectAll('div.game')
      .data( function(d){
        return d.slice(1); } );

      unitsGames.exit().remove();
    var unitsGamesEnter = unitsGames.enter()
      .append('div').attr('class', 'game')
    var unitsGamesMerged = unitsGamesEnter.merge(unitsGames)
      .data( function(d){ return d.slice(1); } );

  //whole plus minus: (units > containers > games' > plus-minus svg)
    var svgPM = unitsGamesMerged.selectAll('svg.pM')
      .data(
        function(d){ return d.plusMinus.filter(k => Math.abs(k.fraction) == 1); },
        function(d){ return d.ordinal; } );

      svgPM.exit().remove();
    var svgPMEnter = svgPM.enter()
      .append('svg').attr('class', 'pMData pMWhole pM')
      .attr('ordinal', function(d){ return d.ordinal })
      .append('rect').attr('class', 'pMData pMWhole pM')
    var svgPMMerged = svgPMEnter.merge(svgPM)
      .data(
        function(d){ return d.plusMinus.filter(k => Math.abs(k.fraction) == 1) },
        function(d){ return d.ordinal; })
      .attr('ordinal', function(d){ return d.ordinal });

  //all fractions: (units > containers > games > fractions div)
    var divFractional = unitsGamesMerged.selectAll('div.pMData.pM.pMFraction')
      .data(
        function(d) { return d.plusMinus.filter(k => k.fractionArray); },
        function(d){ return d.ordinal; } );

      divFractional.exit().remove()
    var divFractionalEnter = divFractional.enter()
      .append('div')
      .attr('class', 'pMData pM pMFraction')
      .attr('ordinal', function(d){ return d.ordinal });
    var divFractionalMerged = divFractionalEnter.merge(divFractional)
      .data(
        function(d){ return d.plusMinus.filter(k => k.fractionArray); },
        function(d){ return d.ordinal; } )
      .attr('ordinal', function(d){ return d.ordinal });


    //svg: (units > containers > games' > fractions div > fraction svg)
    //svg.pM
    var svgPMFraction = divFractionalMerged.selectAll('svg.pMF')
      .data( function(d){ return d.fractionArray.filter(k => k == "pMF" || k.name == "pMF"); } );

      svgPMFraction.exit().remove();
    var svgPMFractionEnter = svgPMFraction.enter()
      .insert('svg', '.per60').attr('class', function(d){
        let classes = ' pMData sub-element pMFraction';
        if (d.name) { return d.name + classes }
        return d + classes;
      })
      .append('rect').attr('class', function(d){
        let classes = ' pMData sub-element pMFraction';
        if (d.name) { return d.name + classes }
        return d + classes;
      })
      // data contains fraction type (pM or per60)
      .attr("rx", 2).attr("ry", 2);

    //svg.per60
    var svgPer60Fraction = divFractionalMerged.selectAll('svg.per60')
      .data( function(d){ return d.fractionArray.filter(k => k == "per60"); } );

      svgPer60Fraction.exit().remove();
    var svgPer60FractionEnter = svgPer60Fraction.enter()
      .append('svg').attr('class', function(d){
        let classes = ' pMData sub-element pMFraction';
        if (d.name) { return d.name + classes }
        return d + classes;
      })
      .append('rect').attr('class', function(d){
        let classes = ' pMData sub-element pMFraction';
        if (d.name) { return d.name + classes }
        return d + classes;
      })
      // data contains fraction type (pM or per60)
      .attr("rx", 2).attr("ry", 2);

    // whole per60: (units > containers > games' > per60 svg)
    var posteriorElement;
    var svgPer60 = unitsGamesMerged.selectAll('svg.pMWhole.per60')
      .data( function(d){ return d.plusMinus.filter(k => k.fraction == 0 && !k.per60Fraction ) } ); //per60Fraction indicates presense of fractions

      svgPer60.exit().remove();
    var svgPer60Enter = svgPer60.enter()
      .insert('svg', function(d) {
        if (posteriorElement && posteriorElement.parentElement != this._parent){
            posteriorElement = null; }
        if (!posteriorElement){
          posteriorElement = d3.select(this._parent)
            .select(`[ordinal="${d.ordinal-1}"] + *`)
            ._groups[0][0] } // <-- gets html node, of selected element
        return posteriorElement; })
      .attr('class', 'pMData pMWhole per60')
      .attr('ordinal', function(d) { return d.ordinal })
      .append('rect').attr('class', 'pMData pMWhole per60')
    var svgPer60Merged = svgPer60.merge(svgPer60Enter)
      .data( function(d){ return d; })
      .attr('ordinal', function(d){ return d.ordinal });
}


export default renderPlusMinus
