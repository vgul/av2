use Mojolicious::Lite;
use Mojo::Util qw(url_escape);
 
# Sample Google OAuth contacts app using Mojolicious
# For more info see:
# https://developers.google.com/google-apps/contacts/v3/
# https://developers.google.com/oauthplayground/
#
# Run this sample app with:
# morbo goauth.pl --listen http://*:5555
 
my $config = plugin Config => { default => {
    # Google OAuth API Key Values
    # Get yours from: https://code.google.com/apis/console#access
    client_id => '289378046980-714n3r204ll8ekb2sdpf8pmkq1b32vnj.apps.googleusercontent.com',
    secret => '_wO8O9l_BKlyR6SIzEIPP09Y',
 
    # Google Contacts Scope
    scope => 'https://www.google.com/m8/feeds/',
    # Google OAuth base uri
    oauth_base => 'https://accounts.google.com/o/oauth2',
    contacts_full =>'contacts/default/full/?alt=json&max-results=3000',
 
    # Application callback (url escaped)
    cb => url_escape( 'http://localhost:5555/cb' ),
}};
 
get '/' => sub { shift->render( 'home' ) };
 
get '/auth' => sub {
    # Redirect user to Googl OAuth Login page
    shift->redirect_to("$config->{oauth_base}/auth" .
        "?client_id=$config->{client_id}&response_type=code" .
        "&scope=$config->{scope}&redirect_uri=$config->{cb}"
    );
};
 
# OAuth 2 callback from google
get '/cb' => sub {
    my ($self) = @_;
 
    #Get tokens from auth code
    my $res = $self->app->ua->post_form("$config->{oauth_base}/token", {
        code => $self->param('code'),
        redirect_uri => $config->{cb},
        client_id => $config->{client_id},
        client_secret => $config->{secret},
        scope => $config->{scope},
        grant_type => 'authorization_code',
    })->res;
 
    die "Error getting tokens" unless $res->is_status_class(200);
 
    # Save access token to session
    $self->session->{access_token} = $res->json->{access_token};
    $self->redirect_to('/contacts');
};
 
get '/contacts' => sub {
    my ($self) = @_;
 
    # Read access token from session
    my $a_token = $self->session->{access_token} or die "No access token!";
 
    # Get the contacts
    my $c_res = $self->app->ua->get(
        "$config->{scope}$config->{contacts_full}",
        { Authorization => "Bearer $a_token" }
    )->res;
 
    die 'Error'  unless $c_res->is_status_class(200);
    $self->stash( contacts => $c_res->json->{feed}{entry} );
};
 
app->start;
 
  __DATA__
@@ home.html.ep
<a href='/auth'>Click here</a> to authenticate with Google OAuth.
 
@@ contacts.html.ep
<html><body>
<% for ( @$contacts ) { %>
    <div>
        <% if ( $_->{'gd$email'}[0] ) { %>
            <%= $_->{title}{'$t'} %>
            &lt;<%= $_->{'gd$email'}[0]{'address'} %>&gt;
        <% } %>
    </div>
<% } %>
</body></html>

