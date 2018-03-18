#!/usr/bin/perl
use strict;
use warnings;
use Socket;
use DateTime;


# use port 7890 as default
my $port = shift || 8080;
my $proto = getprotobyname('tcp');
my $server = "localhost";  # Host IP running the server
my $www = "public"; 

# create a socket, make it reusable
socket(SOCKET, PF_INET, SOCK_STREAM, $proto)
   or die "Can't open socket $!\n";
setsockopt(SOCKET, SOL_SOCKET, SO_REUSEADDR, 1)
   or die "Can't set socket option to SO_REUSEADDR $!\n";

# bind to a port, then listen
bind( SOCKET, pack_sockaddr_in($port, inet_aton($server)))
   or die "Can't bind to port $port! \n";

listen(SOCKET, 5) or die "listen: $!";
print "SERVER started on port $port\n";

# accepting a connection
while (my $client_addr = accept(NEW_SOCKET, SOCKET)) {

  #read request line
  #request-method-name request-URI HTTP-version
  my $req_line = <NEW_SOCKET>;
  my @req = split / /, $req_line; 
  my $req_method = $req[0];
  my $req_uri = $req[1];
  my $req_http_ver = $req[2];
  my ($file_path, $file_size, $file_data);

  #check for default page
  if ($req_uri eq "/") {
    $file_path = "public/index.html" 
  }
  else {
    $file_path = "public".$req_uri;
  }

  #check if file not found 
  if (! -e $file_path) 
  {
      print NEW_SOCKET "HTTP/1.1 404 Not Found\n";
      print NEW_SOCKET "Content-Length: 0\n";
      print NEW_SOCKET "Connection: Closed\n\n";
      close NEW_SOCKET;
      next;
  }


  #file type
  my $content_type;
  if ($file_path =~ /.jpeg$/) {
    $content_type = "image/jpeg";
  }
  elsif ($file_path =~ /.png$/) {
    $content_type = "image/png";
  }
  else {
    $content_type = "text/html";
  }

  #read file content
  $file_size = -s $file_path;
  open(my $fd, "<", $file_path) || die $!;
  sysread $fd, $file_data, $file_size;
  close $fd;

  my $dt = DateTime->now;
  my $res_date = $dt->strftime("%a, %d %b %Y %H:%M:%S GMT");

  #print responce
  print NEW_SOCKET "HTTP/1.1 200 OK\n";
  print NEW_SOCKET "Date: $res_date\n";
  print NEW_SOCKET "Server: Perl 101\n";
  print NEW_SOCKET "Content-Length: $file_size\n";
  print NEW_SOCKET "Content-Type: $content_type\n";
  print NEW_SOCKET "Connection: Closed\n\n";
  print NEW_SOCKET $file_data;
  
  close NEW_SOCKET;
}