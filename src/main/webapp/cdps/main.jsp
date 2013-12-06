<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<html>
<head>
<title>CDPS</title>

<link href="css/custom-theme/jquery-ui-1.10.3.custom.css" rel="stylesheet">
<script src="js/jquery-1.9.1.js"></script>
<script src="js/jquery-ui-1.10.3.custom.js"></script>
<script src="http://code.highcharts.com/stock/highstock.js"></script>
<script src="http://code.highcharts.com/stock/modules/exporting.js"></script>
<script type="text/javascript" src="jscolor/jscolor.js"></script>
<link rel="stylesheet" type="text/css" href="style.css"/>

<script src="<c:url value="/resources/core/jquery.autocomplete.min.js" />"></script>
<link href="<c:url value="/resources/core/main.css" />" rel="stylesheet">


<script>

Date.prototype.yyyymmdd = function() {
   var yyyy = this.getFullYear().toString();
   var mm = (this.getMonth()+1).toString(); // getMonth() is zero-based
   var dd  = this.getDate().toString();
   return yyyy + "-" + (mm[1]?mm:"0"+mm[0]) + "-" + (dd[1]?dd:"0"+dd[0]); // padding
  };


globaldata={};

$(document).ready(function() {
	
	var personalData;
	var speeddata=[];
	var tempdata=[];
	var pressdata=[];
	
	var fromDate = new Date().yyyymmdd();
	var toDate = new Date().yyyymmdd();	
	
	chartloaded=false;
	renderChart();
	getOptions();
	
	var chart=$('#container').highcharts();	
	//getData("Temp",tempdata,fromDate,toDate,"BloodPressure",0)
	//getData("Speed",speeddata,fromDate,toDate,"Speed",1);
	//getData("Pressure",pressdata,fromDate,toDate,"Pressure",2);	
	
	$("#w-get-data").on("click",function(){
		getData("BP",tempdata,fromDate,toDate,"BloodPressure",0);
		getData("COL",tempdata,fromDate,toDate,"Cholesterol",0);
		//alert('Santa is comming to town');
	});
	
	
	function getData(api,dataset, from, to, label, axis){
		$.ajax({
			url: "${pageContext.request.contextPath}/rest/getChartData?id="+ api,
			dataType: "json",
			data: {
				from: from,
				to: to
			},			
			success: function( response) {	
				
				if (depthOf(response[0])>2) {
					dataset=createobjects(response);
				}
				else {
					dataset=createobjects1(response);
				}
				dataset.sort(Comparator);
				var series = {	
						id: label,
						name: label,
						data: dataset,
						yAxis: label+"Axis",						
						dataGrouping: {
							enabled: true
							}
				};	
				
				var chartSeries = getseriesbyname(label);
				if (chartSeries === undefined) {
					chart.addSeries(series);					
				}else{
					chartSeries.setData(dataset);
 				}
							
			}
		});
	}
	
	
	function getOptions(){
			$('#w-input-search').autocomplete({
				serviceUrl: '${pageContext.request.contextPath}/rest/getUid',
				paramName: "tagName",
				delimiter: ",",
				
				onSelect: function(suggestion){
				 $(".details").empty();
				 
				 
				 var $table = $( "<table border='1'></table>" );

				 	var $header = $( "<tr></tr>" );
					$header.append( $( "<th></th>" ).html( "Name" ) );
					$header.append( $( "<th></th>" ).html( "Date of birth" ) );
					$table.append( $header );
					
					var $line = $( "<tr></tr>" );
					$line.append( $( "<td></td>" ).html( suggestion.data.name ) );
					$line.append( $( "<td></td>" ).html( suggestion.data.dob ) );
					$table.append( $line );


				 $('.details').append($table);			
				},
				
			    transformResult: function(response) {

					
	
			        return {
			        	
			            suggestions: $.map($.parseJSON(response), function(item) {
			                return { value: item.id, data: item };
			            })
			            
			        };
			        
			    }
			});
	}
	
	
	
	
	$(document).ajaxStart(function(){
		chart.showLoading('Loading data from server...');
	});
	
	$(document).ajaxStop(function(){
		chart.hideLoading();	
	});
	
	
	
	function createobjects1(obj) {
		var returndata=[];
		//obj = jQuery.parseJSON(obj);
		for (var i=0; i<obj.length; i++){
				var myDate = new Date(obj[i].day);
				var offset = myDate.getTimezoneOffset() * 1000;
				var withOffset = myDate.getTime();
				var withoutOffset = withOffset - offset;
				var basetimestamp = parseInt(withOffset);	
				for (var key in obj[i]) {
					if (key!="id" && key !="day" && key!="_id"){
						timestamp = 0;
						var hour = parseInt(key);
						value=parseFloat(obj[i][key]);
						if(!isNaN(value)){
						    timestamp = basetimestamp + parseInt(hour*3600*1000)
							returndata.push([timestamp,value]);
						}
					 }
				}
			}
		return returndata;	
	}
	
	
	function createobjects(obj) {
		var returndata=[];
		//obj = jQuery.parseJSON(obj);
		for (var i=0; i<obj.length; i++){
				var myDate = new Date(obj[i].day);
				var offset = myDate.getTimezoneOffset() * 1000;
				var withOffset = myDate.getTime();
				var withoutOffset = withOffset - offset;
				var basetimestamp = parseInt(withOffset);				
				for (var key in obj[i]) {
					if (key!="id" && key !="day" && key!="_id"){
						timestamp = 0;
						var hour = parseInt(key*3600*1000);
						//timestamp = basetimestamp + parseInt(key*3600*1000
						for (var min in obj[i][key]){
							var minute = parseInt(min*60*1000);
							for (var milis in obj[i][key][min]){
								var milisecond = parseInt(milis) 
								timestamp = basetimestamp + hour+minute+milisecond;
								value=parseFloat(obj[i][key][min][milis]);
								//timestamps.push(timestamp+parseInt(milis));
								//values.push(value);
								returndata.push([timestamp,value]);
							}
						}
					}
					
				}
			}
		return returndata;	
	}
	
	function depthOf(object) {
		var level = 1;
		var key;
		for(key in object) {
			if (!object.hasOwnProperty(key)) continue;

			if(typeof object[key] == 'object'){
				var depth = depthOf(object[key]) + 1;
				level = Math.max(depth, level);
			}
		}
		return level;
	}
	
	function Comparator(a,b){
		if (a[0] < b[0]) return -1;
		if (a[0] > b[0]) return 1;
		return 0;
	}
	
	
		function renderChart() {
		

		// Create a timer
		//var start = + new Date();

		// Create the chart
		$('#container').highcharts({
		    chart: {
				backgroundColor: '#EFEFEB',				
				
				events: {
					load: function(chart) {
						chartloaded = true;
						this.setTitle(null, {
							//text: 'Built chart at '+ (new Date() - start) +'ms'
						});
						
					}
				},
				zoomType: 'x'
		    },			
			plotOptions: {
				series: {
					marker: {
						enabled: false	
					},
					events: {
						legendItemClick: function () {
							return false; 
						}
					}
				}				
			},
			navigator : {
				//enabled:true
			},
			
			scrollbar: {
				enabled: true
			},
			
			legend: {
				enabled : true,
				title: {text:'Legend'},
                layout: 'vertical',
                align: 'right',
                verticalAlign: 'middle',
                borderWidth: 0,
				width: 200,
				margin:50,
				useHTML: true
            },

		    

			yAxis:[
				{
				id:"BloodPressureAxis",
				title:{
					text:"mmHgs"
					}
				},
				{
				id:"CholesterolAxis",
				title:{
					text:"mg/L"
					}
				}						
			],
			
			xAxis: {
                type: 'datetime',
                //maxZoom: 14 * 24 * 3600000, // fourteen days				
                title: {
                    text: null
                }
            },

		    title: {
				text: ''
			}
			
			
		});
		
		$(".highcharts-legend").click(function(event){
			event.preventDefault();
			return false;
		})
		
	};

	$("#BloodPressure").on("click",function(){
		$(this).find(".icon").toggleClass("add");
		$(this).find(".icon").toggleClass("delete");	
		var series = getseriesbyname("BloodPressure");
		if (series.visible){
			series.hide();
			chart.get("BloodPressureAxis").update({				
				title: {
					text: null
				}
			});
		}else {
			series.show();
			chart.get("BloodPressureAxis").update({				
				title:{
					text:"mmHgs"
					}
				});
		}	
	});
	
	$("#Cholesterol").on("click",function(){	
		$(this).find(".icon").toggleClass("add");
		$(this).find(".icon").toggleClass("delete");	
		var series = getseriesbyname("Cholesterol");
		if (series.visible){
			series.hide();
			chart.get("CholesterolAxis").update({				
				title: {
					text: null
				}
			});
		}else {
			series.show();
			chart.get("CholesterolAxis").update({				
				title:{
					text:"mg/L"
					}
				});
		}	
	});
	$("#pressure").on("click",function(){
		$(this).find(".icon").toggleClass("add");
		$(this).find(".icon").toggleClass("delete");	
		var series = getseriesbyname("Pressure");
		if (series.visible){
			series.hide();
			chart.get("PressureAxis").update({				
				title: {
					text: null
				}
			});
		}else {
			series.show();
			chart.get("PressureAxis").update({
				title:{
					text:"Bar"
					}
				});
		}	
	});

	$(".range-selectors input#from").datepicker({
		dateFormat:"M d, yy",
		onSelect: function(){
			fromDate= new Date($(this).val()).yyyymmdd();
			$(".range-selectors input#to").datepicker( "option", "minDate", new Date($(this).val()) );
			//getData("Temp",tempdata,fromDate,toDate,"BloodPressure",0)
			//getData("Speed",speeddata,fromDate,toDate,"Speed",1);
			//getData("Pressure",pressdata,fromDate,toDate,"Pressure",2);	
		}
	});
	
	$(".range-selectors input#to").datepicker({
		dateFormat:"M d, yy",
		onSelect: function(){
			toDate= new Date($(this).val()).yyyymmdd();
			$(".range-selectors input#from").datepicker( "option", "maxDate", new Date($(this).val()) );
			//getData("Temp",tempdata,fromDate,toDate,"BloodPressure",0)
			//getData("Speed",speeddata,fromDate,toDate,"Speed",1);
			//getData("Pressure",pressdata,fromDate,toDate,"Pressure",2);	
		}
	});
	
	$(".range-selectors input#from").datepicker("setDate", new Date() );
	$(".range-selectors input#to").datepicker("setDate", new Date() );
	
	function getseriesbyname(name){
		for(var i=0;i<chart.series.length;i++){			
			if (chart.series[i].name == name)
				return chart.series[i]
		}
	}
	
	$(".color").on("change",function(){
		chart.get($(this).data("series")).update({
			color:$(this).val()
		});
	});
	
	$(".series-type").on("change",function(){
		chart.get($(this).data("series")).update({
			type:$(this).val()
		});
	});
	
});

//getOptions();

</script>
</head>

<body>

<div id="wrapper">
	<div id="sidebar">
	<fieldset>
		<legend>Search criteria</legend>
		<fieldset>
		<legend>User</legend>
		<label for="from">User id</label><input type="text"  id="w-input-search" value="">	
		</fieldset>
		<fieldset>
		<legend>Dates</legend>		
			<div class="range-selectors">
			<table>
			<tr>
				<td><label for="from">From</label></td>
				<td><input id="from" type="text"/></td>
			</tr>
			<tr>
				<td><label for="to">To</label></td>
				<td><input id="to" type="text"/></td>
			</tr>	
			</table>
			</div>
		</fieldset>
		<div>
			<span>
				<button id="w-get-data" type="button">Load data</button>
			</span>
		</div>
	</fieldset>		
	<fieldset>
		<legend>Personal data</legend>
		<div class="details">
		</div>
	</fieldset> 
	</div>
	<div id="content">
		<div id="inner-content">
			<h1>Data graph</h1>			
			<div id="container"></div>
			<div class="details"></div>
			<!--div class="buttongroup">
				<div>
					<button id="BloodPressure">BloodPressure<span class="icon delete"></span></button>	
					Color:<input data-series="BloodPressure" class="color {hash:true}" value="66ff00">
					<select data-series="BloodPressure" class="series-type">
						<option value="line">Line</option>
						<option value="area">Area</option>					
						<option value="column">Column</option>						
					</select>
				</div>
			</div-->
		</div>
	</div>
</div>



</body>

</html>