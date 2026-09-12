#!/bin/bash
# Update packages
dnf update -y

# Install Apache (httpd), PHP and MySQL extension
dnf install -y httpd php php-mysqli mariadb105

# Start and enable Apache Web Server
systemctl start httpd
systemctl enable httpd

# Create dbinfo directory outside public document root (/var/www/inc/dbinfo.inc)
mkdir -p /var/www/inc
cat << 'EOF_DB' > /var/www/inc/dbinfo.inc
<?php
define('DB_SERVER', '${db_endpoint}');
define('DB_USERNAME', '${db_username}');
define('DB_PASSWORD', '${db_password}');
define('DB_DATABASE', '${db_name}');
?>
EOF_DB

chmod 644 /var/www/inc/dbinfo.inc

# Write the user's index.php file
cat << 'EOF_PHP' > /var/www/html/index.php
<?php include "../inc/dbinfo.inc"; ?>
<html>
<body>
<h1> Welcome to my project website !</h1>
<?php

  /* Connect to MySQL and select the database. */
  $connection = mysqli_connect(DB_SERVER, DB_USERNAME, DB_PASSWORD);

  if (mysqli_connect_errno()) echo "Failed to connect to MySQL: " . mysqli_connect_error();

  $database = mysqli_select_db($connection, DB_DATABASE);

  /* Ensure that the EMPLOYEES table exists. */
  VerifyEmployeesTable($connection, DB_DATABASE);

  /* If input fields are populated, add a row to the EMPLOYEES table. */
  $employee_name = isset($_POST['NAME']) ? htmlentities($_POST['NAME']) : '';
  $employee_age = isset($_POST['AGE']) ? htmlentities($_POST['AGE']) : '';
  $employee_city = isset($_POST['CITY']) ? htmlentities($_POST['CITY']) : '';

  if (strlen($employee_name) || strlen($employee_city)) {
    AddEmployee($connection, $employee_name, $employee_age, $employee_city);
  }
?>

<!-- Input form -->
<form action="<?PHP echo $_SERVER['SCRIPT_NAME'] ?>" method="POST">
  <table border="0">
    <tr>
      <td>NAME</td>
      <td>AGE</td>
      <td>CITY</td>
    </tr>
    <tr>
      <td>
        <input type="text" name="NAME" maxlength="45" size="30" />
      </td>
      <td>
        <input type="text" name="AGE" maxlength="45" size="30" />
      </td>
      <td>
        <input type="text" name="CITY" maxlength="45" size="30" />
      </td>
      <td>
        <input type="submit" value="Add Data" />
      </td>
    </tr>
  </table>
</form>

<!-- Display table data. -->
<table border="1" cellpadding="2" cellspacing="2">
  <tr>
    <td>ID</td>
    <td>NAME</td>
    <td>AGE</td>
    <td>CITY</td>
  </tr>

<?php

$result = mysqli_query($connection, "SELECT * FROM EMPLOYEES");

if ($result) {
  while($query_data = mysqli_fetch_row($result)) {
    echo "<tr>";
    echo "<td>",$query_data[0], "</td>",
         "<td>",$query_data[1], "</td>",
         "<td>",$query_data[2], "</td>",
         "<td>",$query_data[3], "</td>";
    echo "</tr>";
  }
  mysqli_free_result($result);
}
?>

</table>

<!-- Clean up. -->
<?php

  if ($connection) {
    mysqli_close($connection);
  }

?>

</body>
</html>


<?php

/* Add an employee to the table. */
function AddEmployee($connection, $name, $age, $city) {
   $n = mysqli_real_escape_string($connection, $name);
   $a = mysqli_real_escape_string($connection, $age);
   $c = mysqli_real_escape_string($connection, $city);

   $query = "INSERT INTO EMPLOYEES (NAME, AGE, CITY) VALUES ('$n', '$a', '$c');";

   if(!mysqli_query($connection, $query)) echo("<p>Error adding employee data: " . mysqli_error($connection) . "</p>");
}

/* Check whether the table exists and, if not, create it. */
function VerifyEmployeesTable($connection, $dbName) {
  if(!TableExists("EMPLOYEES", $connection, $dbName))
  {
     $query = "CREATE TABLE EMPLOYEES (
         ID int(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
         NAME VARCHAR(45),
         AGE INTEGER(3),
         CITY VARCHAR(45)
       )";

     if(!mysqli_query($connection, $query)) echo("<p>Error creating table: " . mysqli_error($connection) . "</p>");
  }
}

/* Check for the existence of a table. */
function TableExists($tableName, $connection, $dbName) {
  $t = mysqli_real_escape_string($connection, $tableName);
  $d = mysqli_real_escape_string($connection, $dbName);

  $checktable = mysqli_query($connection,
      "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_NAME = '$t' AND TABLE_SCHEMA = '$d'");

  if(mysqli_num_rows($checktable) > 0) return true;

  return false;
}
?>
EOF_PHP

# Set ownership and permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html
