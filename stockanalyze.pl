#!/opt/local/bin/perl -w 

use LWP::Simple;
use Getopt::Std;
use Getopt::Long;

my @stocks;
my $amount;
my $inprice;

GetOptions('s|stock=s' => \@stocks,
	   'a|amount=s' => \$amount,
	   'ip|inprice=f' => \$inprice,
	   'lp|lowestprice=f' => \$ever_low,
	   'hp|highestprice=f' => \$ever_high);

if(@stocks < 1 or !$amount or !$inprice) {
  print "Usage: ./stockanalyze -s <stockid> -a <amount_of_stocks> -ip <inprice> -lp <lowest_price> -hp <highest_price>\n";
}

my $browser = LWP::UserAgent->new;
my $baseurl = "https://www.avanza.se/aza/aktieroptioner/kurslistor/aktie.jsp?orderbookId=";

foreach my $stockid (@stocks) {


	my $response = $browser->get($baseurl . $stockid);
	die "Error at $baseurl$stockid\n ", $response->status_line, "\n Aborting"
	  unless $response->is_success;

	@content = split('\n', $response->content);

	foreach my $line (@content) 
	  { 
	    if ($line =~ m/\<td align\=\'left\' nowrap class\=\"link\"\>(.*?)\<\/td\>\<td nowrap class\=\"(.*?)\"\>(.*?)\<\/td\>\<td nowrap class\=\".*?\"\>(.*?)\<\/td\>\<td nowrap class\=\".*?\"\>(.*?)\<\/td\>\<td nowrap class\=\".*?\"\>(.*?)\<\/td\>\<td nowrap class\=\".*?\"\>(.*?)\<\/td\>\<td nowrap class\=\".*?\"\>(.*?)\<\/td\>\<td nowrap class\=\".*?\"\>(.*?)\<\/td\>\<td nowrap class\=\".*?\"\>(.*?)\<\/td\>\<td nowrap class\=\".*?\"\>(.*?)\<\/td\>/i) {

	      
	      ## Put all matches into variables
	      my $stock_name = $1;
	      my $state = $2;
	      my $change_value = $3;
	      my $change_percent = $4;
	      my $buy_price = $5;
	      my $sell_price = $6;
	      my $last_price = $7;
	      my $highest_price = $8;
	      my $lowest_price = $9;
	      my $s_amount = $10;
	      my $time = $11;

	      ## Replace commas(,) with dots(.) 
	      $change_value =~ s/\,/\./g;
	      $change_percent =~ s/\,/\./g;
	      $buy_price =~ s/\,/\./g;
	      $sell_price =~ s/\,/\./g;
	      $last_price =~ s/\,/\./g;
	      $highest_price =~ s/\,/\./g;
	      $lowest_price =~ s/\,/\./g;

	      ## Give a overview of the stock
	      print "----------------------------------\n";
	      print "* $stock_name\n";
	      print "----------------------------------\n";
	      print " +/- (Value):\t $change_value\n";
	      print " +/- (Perce):\t $change_percent\n";
	      print " Buy price:\t $buy_price\n";
	      print " Sell price:\t $sell_price\n";
	      print " Last price:\t $last_price\n";
	      print " Highest price:\t $highest_price\n";
	      print " Lowest price:\t $lowest_price\n";
	      print " Last updated:\t $time\n\n";

	      ## The analyze
	      my $worth_now; ## What the stocks are worth now
	      my $worth_first; ## What the stocks was worth when initially bought
	      my $worth_first_courtage; ## What is the stocks initially worth if we would sell them again?
	      my $worth_after_courtage; ## What the current hold of stocks would be worth after courtage
	      my $median_price; ## The median value of lowest/highest
	      my $median_ever = 0; ## Median value of the lowest/highest value given by the user

	      ## Calculate what the stocks are worth now/when first bought
	      $worth_first = $inprice*$amount;
	      if($sell_price eq "0.00") {
		$worth_now = $last_price*$amount;
	      } else {
		$worth_now = $sell_price*$amount;
	      }

	      ## Calculate median value
	      $median_price = (($highest_price-$lowest_price)/2)+$lowest_price;
	      if($ever_high and $ever_low) {
		$median_ever = (($ever_high-$ever_low)/2)+$ever_low;
		print "The median price is: $median_ever SEK\n";
	      }
	      # print "The median price is: $median_price\n";
	      print "Your stocks are worth: \t$worth_now SEK\n";
	      print "You bought the stocks for:\t $worth_first SEK\n";

	      ## Calculate what the value of the stocks are if we take the courtage into account
	      if($worth_now*0.0009 > 99.0) {
		$worth_after_courtage = $worth_now-($worth_now*0.0009);
	      } else {
		$worth_after_courtage = $worth_now-99.0;
	      }

	      if($worth_first*0.0009 > 99.0) {
		$worth_first_courtage = $worth_first-($worth_first*0.0009);
	      } else {
		$worth_first_courtage =  $worth_first-99.0;
	      }

	      if($median_ever) {
		if($median_ever > $worth_now) {
		  ## The stocks are worth more than the median value (Good or bad?)
		  print "The stocks are worth more than the average value with: " . ($median_ever/$worth_now)*10 . "%\n";
		} else {
		  print "The stocks are worth less than the average value with: " . ($median_ever/$worth_now)*10 . "%\n";
		}
	      }


	      
	      ## Check if there is any profit to be made
	      if($worth_after_courtage > $worth_first) {
		print "You will make a profit of " . ($worth_after_courtage-$worth_first) . "SEK if you sell your stocks now\n";
	      } else {
		## We have a negative profit. Calculate how much we've loosed on this
		my $loose_ratio = $worth_now / $worth_first_courtage;
		$loose_ratio = 1-$loose_ratio;
		if($loose_ratio > 0.10) {
		  print "Your loose is higher than 10%. The current loose is " . $loose_ratio*100 . "%\n";
		} else {
		  print "Your loose is less than 10%. Recommend to keep an extra eye on this stock. Current loose percentage is " . $loose_ratio*100 . "%\n";
		}
	      }
	      

	      
	    }
	  }
	
      }
