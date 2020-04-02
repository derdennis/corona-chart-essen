// Get the data
d3.csv("cases.csv", function (error, data) {
    if (error) throw error;

    // The table generation function
    function tabulate(data, columns) {
        var table = d3.select("#table").append("table")
            .attr("style", "margin-left: 400px"),
            thead = table.append("thead"),
            tbody = table.append("tbody");

        // append the header row
        thead.append("tr")
            .selectAll("th")
            .data(columns)
            .enter()
            .append("th")
            .text(function (column) {
                return column;
            });

        // create a row for each object in the data
        var rows = tbody.selectAll("tr")
            .data(data)
            .enter()
            .append("tr");

        // create a cell in each row for each column
        var cells = rows.selectAll("td")
            .data(function (row) {
                return columns.map(function (column) {
                    return {
                        column: column,
                        value: row[column]
                    };
                });
            })
            .enter()
            .append("td")
            .attr("style", "font-family: Courier") // sets the font style
            .html(function (d) {
                return d.value;
            });

        return table;
    }

    // render the table
    var casesTable = tabulate(data, ["date", "cases"]);

});
