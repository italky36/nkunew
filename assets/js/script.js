$('.bars').click(function() {
    $('.mob-menu').fadeIn(300);
    $('.shadow').fadeIn(0);
});
$('.mob-menu-close').click(function() {
    $('.mob-menu').fadeOut(300);
    $('.shadow').fadeOut(0);
});


$('.feedback-sub .btn').click(function() {
    for (let i = 0; i < 2; i++) {
        if ($('.feedback-input-block input').eq(i).val() == "") {
            $('.feedback-input-block input').eq(i).addClass('war');
        } else {
            $('.feedback-input-block input').eq(i).removeClass('war');
        }
    }
});

if ($(window).width() < 767) {
    $(window).scroll(function() {
        if ($(this).scrollTop() > 0) {
            $('.header').addClass('active');
        } else {
            $('.header').removeClass('active');
        }
    });
} else {

}


$('.production-slider').slick({
    slidesToShow: 1,
    centerMode: true,
    prevArrow: $('.production-slider-direction .left-arrow'),
    nextArrow: $('.production-slider-direction .right-arrow'),
    centerPadding: '450px',
    dots: true,
    responsive: [{
            breakpoint: 1750,
            settings: {
                centerPadding: '380px',
            }
        },
        {
            breakpoint: 1400,
            settings: {
                centerPadding: '300px',
            }
        },
        {
            breakpoint: 1200,
            settings: {
                centerPadding: '80px',
            }
        },
        {
            breakpoint: 992,
            settings: {
                centerPadding: '0px',
            }
        },
    ]
});
$('.performance-slider').slick({
    slidesToShow: 1,
    prevArrow: $('.performance-slider-direction .left-arrow'),
    nextArrow: $('.performance-slider-direction .right-arrow'),
    responsive: [{
            breakpoint: 1750,
            settings: {
                centerPadding: '380px',
            }
        },
        {
            breakpoint: 1400,
            settings: {
                centerPadding: '300px',
            }
        },
    ]
});


$(window).scroll(function() {
    if ($(this).scrollTop() > 0) {
        $('.scroll-block').fadeIn(100);
    } else {
        $('.scroll-block').fadeOut(100);
    }
});
$('.scroll-block').click(function() {
    $("html, body").animate({ scrollTop: 0 }, "slow");
    return false;
});